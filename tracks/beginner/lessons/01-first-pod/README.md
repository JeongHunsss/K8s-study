# 1강: 첫 Pod 실행하기

## 학습 목표

이 실습을 마치면 다음을 할 수 있습니다.

- 클러스터, 노드, Pod, 컨테이너의 관계를 설명한다.
- YAML 매니페스트를 읽고 `kubectl apply`로 리소스를 만든다.
- `get`, `describe`, `logs`로 Pod를 관찰한다.
- 포트 포워딩으로 Pod의 웹 서버에 접속한다.
- 생성한 리소스를 안전하게 정리한다.

예상 시간은 60~90분입니다.

## 0. 준비물

- Docker Desktop이 실행 중이어야 합니다.
- `kubectl`과 `kind`가 설치되어 있어야 합니다.
- 저장소 루트에서 Git Bash를 실행합니다.

설치되지 않았다면 공식 안내를 따라 준비합니다.

- [Docker Desktop 설치](https://docs.docker.com/desktop/setup/install/windows-install/)
- [kubectl 설치](https://kubernetes.io/docs/tasks/tools/)
- [kind 빠른 시작](https://kind.sigs.k8s.io/docs/user/quick-start/)

환경을 확인합니다.

```bash
./tracks/beginner/lessons/01-first-pod/scripts/check-environment.sh
```

모든 항목이 `[OK]`여야 다음 단계로 진행할 수 있습니다.

## 1. 로컬 클러스터 만들기

```bash
kind create cluster --name k8s-study
kubectl cluster-info --context kind-k8s-study
kubectl get nodes
```

노드의 `STATUS`가 `Ready`이면 성공입니다. 이미 같은 이름의 클러스터가 있다면 생성 명령은 생략합니다.

## 2. 매니페스트 읽기

[namespace.yaml](manifests/namespace.yaml)은 실습 리소스를 격리할 `k8s-study` Namespace를 만듭니다. [pod.yaml](manifests/pod.yaml)은 그 Namespace에 nginx 컨테이너 하나를 실행합니다.

Pod 매니페스트에서 다음 항목을 찾아봅니다.

- `apiVersion`, `kind`: 어떤 Kubernetes API 리소스인지 나타냅니다.
- `metadata.name`, `metadata.namespace`: 리소스의 이름과 소속 공간입니다.
- `metadata.labels`: 리소스를 분류하고 선택할 때 쓰는 키-값 정보입니다.
- `spec.containers`: Pod에서 실행할 컨테이너의 원하는 상태입니다.

## 3. Namespace와 Pod 만들기

```bash
kubectl apply -f ./tracks/beginner/lessons/01-first-pod/manifests/namespace.yaml
kubectl apply -f ./tracks/beginner/lessons/01-first-pod/manifests/pod.yaml
kubectl get pods -n k8s-study --watch
```

`STATUS`가 `Running`, `READY`가 `1/1`이 되면 `Ctrl+C`로 감시를 종료합니다.

## 4. Pod 관찰하기

```bash
kubectl get pod web -n k8s-study -o wide
kubectl describe pod web -n k8s-study
kubectl logs web -n k8s-study
```

확인할 내용:

1. Pod가 어느 노드에 배치되었나요?
2. 컨테이너 이미지 이름은 무엇인가요?
3. `Events`에는 스케줄링, 이미지 가져오기, 컨테이너 시작이 어떤 순서로 기록되었나요?

첫 요청 로그는 아직 비어 있을 수 있습니다.

## 5. 웹 서버 접속하기

첫 번째 Git Bash 창에서 포트 포워딩을 실행합니다.

```bash
kubectl port-forward pod/web 8080:80 -n k8s-study
```

두 번째 Git Bash 창에서 요청을 보냅니다.

```bash
curl --head http://localhost:8080
kubectl logs web -n k8s-study
```

응답 코드 `200`과 nginx 접근 로그가 보이면 성공입니다. 확인 후 첫 번째 창에서 `Ctrl+C`를 누릅니다.

## 6. 선언적 상태 체험하기

현재 Pod를 삭제하고 다시 적용합니다.

```bash
kubectl delete pod web -n k8s-study
kubectl get pods -n k8s-study
kubectl apply -f ./tracks/beginner/lessons/01-first-pod/manifests/pod.yaml
kubectl wait --for=condition=Ready pod/web -n k8s-study --timeout=90s
```

순수 Pod는 삭제 후 자동으로 복구되지 않습니다. 매니페스트를 다시 적용해야 돌아옵니다. 2강에서는 Deployment가 이 복구를 자동화하는 과정을 실습합니다.

## 7. 정리하기

실습 리소스만 지우려면 다음을 실행합니다.

```bash
kubectl delete namespace k8s-study
```

클러스터까지 제거하려면 다음을 실행합니다.

```bash
kind delete cluster --name k8s-study
```

## 완료 체크

- [ ] 노드의 `Ready` 상태를 확인했다.
- [ ] YAML로 Namespace와 Pod를 생성했다.
- [ ] `describe`의 Events를 순서대로 읽었다.
- [ ] 웹 요청 결과와 컨테이너 로그를 확인했다.
- [ ] Pod 삭제 후 자동 복구되지 않는 이유를 설명할 수 있다.
- [ ] 실습 리소스를 정리했다.

## 자주 만나는 문제

- `kind: command not found`: kind 설치 후 새 Git Bash 창을 엽니다.
- Docker 연결 오류: Docker Desktop을 시작하고 엔진이 준비될 때까지 기다립니다.
- `ImagePullBackOff`: 인터넷 연결과 `kubectl describe pod`의 Events를 확인합니다.
- 8080 포트 사용 중: `kubectl port-forward pod/web 8081:80 -n k8s-study`처럼 로컬 포트만 바꿉니다.
