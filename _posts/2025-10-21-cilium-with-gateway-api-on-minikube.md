---
layout: post
title: ciliumのGateway APIをminikubeで試した
date: 2025-10-16 16:45 +0900
comments: true
category: blog
tags: kubernetes minikube cilium
---
cilium の Gateway API Support を有効にして Gateway や HTTPRoute や CiliumNetworkPolicy の動作を確認したかったので、
minikube で試せる環境を作成しました。
(CiliumNetworkPolicy は この記事の対象外です。)
<!--more-->

## 動作確認環境

- macOS Sequoia 15.7.1
- `colima` 0.9.1 で動かしている docker 環境
- `minikube` v1.37.0
- `vfkit` 0.6.1
- `kubectl` v1.34.1
- `cilium-cli` v0.18.7

## 8080 番ポートで動作確認

privileged port は別途設定追加が必要なので、
最初に 8080 番ポートで動作確認しました。

ホスト側の macOS からノードの IP アドレスに直接接続できるようにするため、
[vfkit](https://minikube.sigs.k8s.io/docs/drivers/vfkit/) を使ったので、
`brew install vfkit` でインストールしておく必要があります。

`minikube` は `--cni cilium` に対応していましたが、
Gateway API CRDs を cilium より先に入れる必要があったので
`--cni false` にしました。

gateway-api の最新は 1.4.0 になっていますが、
cilium との組み合わせが確認されている 1.3.0 にしました。

`gatewayAPI.hostNetwork.enabled=true` で `NodePort` などを使わずに直接見えるようにしました。
これと `vfkit` の組み合わせでホスト側のブラウザーなどからも直接見えるようになります。

80番ポートは `default/cilium-gateway-cilium-gateway/listener: cannot bind '0.0.0.0:80': Permission denied` (cilium の pod のログで確認) で使えないので 8080 番ポートにしています。

動作確認のテスト用アプリケーションは Claude が出してくれたものを使いました。
テスト用なので Gateway なども default namespace のままになっています。

起動待ちをしていないため、最後の curl で表示されなかったので別途実行して確認しました。

```bash
#!/bin/bash
set -euxo pipefail

# 最終的な構成
minikube start \
  --driver=vfkit \
  --network-plugin=cni \
  --cni=false \
  --extra-config=kubeadm.skip-phases=addon/kube-proxy

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=$(minikube ip) \
  --set k8sServicePort=8443 \
  --set gatewayAPI.enabled=true \
  --set gatewayAPI.hostNetwork.enabled=true \
  --set ingressController.enabled=false

cilium status --wait

# Gateway (8080ポート)
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cilium-gateway
spec:
  gatewayClassName: cilium
  listeners:
  - name: http
    protocol: HTTP
    port: 8080
EOF

# テスト用アプリケーション
kubectl create deployment echo --image=ealen/echo-server:latest
kubectl expose deployment echo --port=80

# HTTPRoute
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
spec:
  parentRefs:
  - name: cilium-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: echo
      port: 80
EOF

# テスト
curl http://$(minikube ip):8080
```

## 80番ポートで確認

80番ポートを使えるようにするには
<https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/>
の説明にあるように `envoy.securityContext.capabilities` の設定も必要でした。

`values.yaml` に書くなら以下のようになります。

```yaml
envoy:
  securityContext:
    capabilities:
      keepCapNetBindService: true
      envoy:
      - NET_ADMIN
      - SYS_ADMIN
      # Add NET_BIND_SERVICE to the list (keep the others!)
      - NET_BIND_SERVICE
```

keep the others! 用の値は cilium の chart の `values.yaml` の以下のところから持ってきています。

```yaml
    capabilities:
      # -- Capabilities for the `cilium-envoy` container.
      # Even though granted to the container, the cilium-envoy-starter wrapper drops
      # all capabilities after forking the actual Envoy process.
      # `NET_BIND_SERVICE` is the only capability that can be passed to the Envoy process by
      # setting `envoy.securityContext.capabilities.keepNetBindService=true` (in addition to granting the
      # capability to the container).
      # Note: In case of embedded envoy, the capability must  be granted to the cilium-agent container.
      envoy:
        # Used since cilium proxy uses setting IPPROTO_IP/IP_TRANSPARENT
        - NET_ADMIN
        # We need it for now but might not need it for >= 5.11 specially
        # for the 'SYS_RESOURCE'.
        # In >= 5.8 there's already BPF and PERMON capabilities
        - SYS_ADMIN
        # Both PERFMON and BPF requires kernel 5.8, container runtime
        # cri-o >= v1.22.0 or containerd >= v1.5.0.
        # If available, SYS_ADMIN can be removed.
        #- PERFMON
        #- BPF
      # -- Keep capability `NET_BIND_SERVICE` for Envoy process.
      keepCapNetBindService: false
```

最終的に動作確認用のコマンドは以下のようになりました。

```bash
#!/bin/bash
set -euxo pipefail

# 最終的な構成
minikube start \
  --driver=vfkit \
  --network-plugin=cni \
  --cni=false \
  --extra-config=kubeadm.skip-phases=addon/kube-proxy

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=$(minikube ip) \
  --set k8sServicePort=8443 \
  --set gatewayAPI.enabled=true \
  --set gatewayAPI.hostNetwork.enabled=true \
  --set ingressController.enabled=false \
  --set envoy.securityContext.capabilities.keepCapNetBindService=true \
  --set envoy.securityContext.capabilities.envoy='{NET_ADMIN,SYS_ADMIN,NET_BIND_SERVICE}'

cilium status --wait

# Gateway (8080ポート)
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cilium-gateway
spec:
  gatewayClassName: cilium
  listeners:
  - name: http
    protocol: HTTP
    port: 80
EOF

# テスト用アプリケーション
kubectl create deployment echo --image=ealen/echo-server:latest
kubectl expose deployment echo --port=80

# HTTPRoute
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
spec:
  parentRefs:
  - name: cilium-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: echo
      port: 80
EOF

# テスト
curl --head http://$(minikube ip)
```

## 最後に

いくつかはまりどころがありましたが、
やりたかったことができる環境を作成できました。

これで既存の環境を壊さずに CiliumNetworkPolicy の設定を試行錯誤できそうです。
