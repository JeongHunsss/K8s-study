# 2강: Deployment와 자가 복구

## 학습 목표

이 실습을 마치면 다음을 할 수 있습니다.

- ReplicaSet과 Deployment의 관계를 설명한다.
- `selector`와 `template.metadata.labels`가 어떻게 연결되는지 설명한다.
- Pod를 강제로 삭제해 Deployment의 자가 복구를 관찰한다.
- `kubectl scale`로 복제본 수를 조정하고 결과를 확인한다.
- 생성한 리소스를 안전하게 정리한다.

예상 시간은 60~90분입니다.

## 0. 준비물

- Docker Desktop이 실행 중이어야 합니다.
- `kubectl`과 `kind`가 설치되어 있어야 합니다.
- 1강을 완료했거나, 1강의 클러스터 생성 단계를 이미 알고 있어야 합니다.
- 저장소 루트에서 Git Bash를 실행합니다.

환경을 확인합니다.

```bash
./tracks/beginner/lessons/02-deployment-self-healing/scripts/check-environment.sh
```

모든 항목이 `[OK]`여야 다음 단계로 진행할 수 있습니다.

## 1. 클러스터 확인하기

```bash
kubectl cluster-info --context kind-k8s-study
kubectl get nodes
```

클러스터가 없다면 1강의 방법대로 새로 만듭니다.

```bash
kind create cluster --name k8s-study
```

1강의 리소스를 정리하지 않았다면 이번 강의를 시작하기 전에 정리합니다.

```bash
kubectl delete namespace k8s-study --ignore-not-found
```

## 2. 매니페스트 읽기

[namespace.yaml](manifests/namespace.yaml)은 1강과 같은 `k8s-study` Namespace를 만듭니다. [deployment.yaml](manifests/deployment.yaml)은 nginx Pod 3개를 유지하는 Deployment를 정의합니다.

Deployment 매니페스트에서 다음 항목을 찾아봅니다.

- `spec.replicas`: 유지하려는 Pod의 개수입니다.
- `spec.selector.matchLabels`: Deployment가 어떤 라벨의 Pod를 자신의 것으로 인식할지 정합니다.
- `spec.template`: 새로 만들 Pod의 설계도입니다. `metadata.labels`가 `selector.matchLabels`와 일치해야 합니다.

`selector`와 `template.labels`가 일치하지 않으면 `kubectl apply`가 오류로 거부합니다. 두 값이 반드시 짝을 이뤄야 하는 이유입니다.

## 3. Deployment 만들기

```bash
kubectl apply -f ./tracks/beginner/lessons/02-deployment-self-healing/manifests/namespace.yaml
kubectl apply -f ./tracks/beginner/lessons/02-deployment-self-healing/manifests/deployment.yaml
kubectl get deployment web -n k8s-study --watch
```

`READY`가 `3/3`이 되면 `Ctrl+C`로 감시를 종료합니다.

## 4. Deployment, ReplicaSet, Pod 관계 관찰하기

```bash
kubectl get deployment,replicaset,pod -n k8s-study -o wide
kubectl describe deployment web -n k8s-study
```

확인할 내용:

1. ReplicaSet의 이름은 Deployment 이름 뒤에 어떤 값이 붙어 있나요?
2. Pod의 이름은 ReplicaSet 이름 뒤에 어떤 값이 붙어 있나요?
3. `describe deployment`의 `Events`에는 ReplicaSet 생성이 어떻게 기록되나요?

Deployment는 직접 Pod를 만들지 않고 ReplicaSet을 통해 만듭니다. Deployment는 ReplicaSet의 개수와 버전을 관리하고, ReplicaSet은 Pod의 개수를 관리합니다.

## 5. 자가 복구 체험하기

Pod 하나를 라벨로 선택해 이름을 확인하고 강제로 삭제합니다.

```bash
kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx
target_pod=$(kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod "$target_pod" -n k8s-study
kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx --watch
```

`READY`가 다시 `3/3`이 되면 `Ctrl+C`로 감시를 종료합니다.

```bash
kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx
```

1강에서는 Pod를 삭제하면 복구되지 않았지만, 이번에는 이름이 다른 새 Pod가 생겼습니다. ReplicaSet이 원하는 개수(3개)와 실제 개수를 계속 비교하다가, Pod가 하나 사라지자 즉시 새 Pod를 만들었기 때문입니다.

## 6. 스케일 조정하기

```bash
kubectl scale deployment/web --replicas=5 -n k8s-study
kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx --watch
```

`READY`가 `5/5`가 되면 `Ctrl+C`로 감시를 종료합니다. 이번에는 원래 개수로 되돌립니다.

```bash
kubectl scale deployment/web --replicas=3 -n k8s-study
kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx --watch
```

`READY`가 `3/3`이 되면 `Ctrl+C`로 감시를 종료합니다. 개수를 줄이면 ReplicaSet이 초과된 Pod를 스스로 종료합니다.

## 7. 정리하기

실습 리소스만 지우려면 다음을 실행합니다.

```bash
kubectl delete namespace k8s-study
```

클러스터까지 제거하려면 다음을 실행합니다.

```bash
kind delete cluster --name k8s-study
```

3강에서는 같은 클러스터에서 이미지 버전을 바꿔가며 롤링 업데이트와 롤백을 실습하므로, 클러스터는 남겨두어도 괜찮습니다.

## 완료 체크

- [ ] Deployment, ReplicaSet, Pod의 이름 규칙과 관계를 설명했다.
- [ ] `selector`와 `template.labels`가 일치해야 하는 이유를 설명했다.
- [ ] Pod를 강제로 삭제한 뒤 자동으로 복구되는 과정을 관찰했다.
- [ ] `kubectl scale`로 복제본 수를 늘리고 줄이며 결과를 확인했다.
- [ ] 실습 리소스를 정리했다.

## 자주 만나는 문제

- `error: error validating data`: `deployment.yaml`의 `spec.selector.matchLabels`와 `spec.template.metadata.labels`가 정확히 일치하는지 확인합니다.
- 새 Pod가 `Pending`에 머무름: `kubectl describe pod <pod-name> -n k8s-study`의 `Events`에서 스케줄링 실패 원인을 확인합니다.
- `target_pod` 변수가 비어 있음: `kubectl get pods -n k8s-study -l app.kubernetes.io/name=nginx`로 Pod가 `Running` 상태인지 먼저 확인합니다.
- 이전 강의 리소스와 충돌: 3단계의 정리 명령으로 `k8s-study` Namespace를 삭제한 뒤 다시 시작합니다.
