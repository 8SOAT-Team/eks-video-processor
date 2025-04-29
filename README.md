# 💡 Introdução

## Objetivo ##
Este repositório contém uma estrutura de arquivos `hcl` para o provisionamento de infraestrutura na AWS. Esta arquitetura é composta pelo EKS organizado em um único módulos distinto para facilitar a manutenção e escalabilidade.

## 📦 Estrutura ##

- *eks:* Provisionamento do cluster EKS.

### Pré-requisitos

- *AWS CLI:* Configurado com um perfil para autenticação.
- *Terraform:* Certifique-se de que a versão instalada seja compatível com os provedores declarados (~> 4.0).

### Configuração Inicial

- *Configurar o AWS CLI:* Execute ´aws configure´ e configure o perfil de autenticação com as credenciais apropriadas para provisionar a infraestrutura na região `us-east-1` juntamente com uma *access_key* e uma *secret_key*.
- *Configurar o backend do Terraform:* A pasta `eks` possui um backend remoto cujo state é salvo em um Workspace do Terraform Cloud, por isso é necessário em execuções locais executar o [Terraform Login](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-login#start-the-login-flow).

### Como as Actons Funcionam?
- Para executar o Apply ou Destroy em sua infraestrutura basta selcionar o workspace `Terraform Apply/Destroy`em seguida clique em `run workflow`. Selecione ação *(apply ou destroy)*, por último escolha o módulo desejado.
- As Actions utilizam um backend remoto da Hascorp para guardar o arquivo do State, para isso caso seja necessário gerenciar a infraestrutura por uma outra conta de AWS é necessário alterar dentro do Workflow criado no Terraform Cloud as vériaveis de ambiente *(AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY)* além do `HASHICORP_TOKEN` que será gerado em sua respectiva conta.

- Para integrar todo este backend com o terraform preciso declar esta estrutura no arquivo `providers.tf`:

```hcl
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "sua-org"

    workspaces {
      name = "seu-workspace"
    }
  }
```

- *hostname* = Sempre vai ser `app.terraform.io`
- *organization* = Aqui declaramos a organizarion em que estão inseridos os workspaces, caso necessário troque este valor para o sua organization criada posteriormente.
- *workspaces* = Aqui declaramos o nome do workspace, caso necessário troque este valor para o seu workspace criado posteriormente.


## Como Provisionar Recursos ##

### Provisionar o Cluster EKS

Acesse e execute os seguintes comandos na pasta `eks:`

```bash
terraform init
terraform apply

```
---

# 📘 Configurando IRSA com OIDC via `eksctl` + Terraform

## Visão geral

Este processo habilita o OIDC no cluster Amazon EKS usando `eksctl` e ajusta o código Terraform (`irsa.tf`) para autenticar workloads via IRSA (IAM Roles for Service Accounts).

---

## Pré-requisitos

- Cluster EKS já provisionado
- `eksctl` instalado ([guia oficial](https://eksctl.io/introduction/installation/))
- Acesso ao AWS CLI configurado (`~/.aws/credentials`)
- Terraform CLI (versão compatível com o Terraform Cloud)

---

## Habilitar o OIDC Provider via `eksctl`

> Quando o cluster é recriado, ele recebe um **novo OIDC issuer** e um novo endpoint. É necessário habilitar esse novo issuer no IAM da conta AWS.

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster video-processor-eks-cluster \
  --approve
```

## Install CSI

```bash
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
--namespace kube-system \
--create-namespace
```

```bash
kubectl annotate serviceaccount ebs-csi-controller-sa \
-n kube-system \
eks.amazonaws.com/role-arn=arn:aws:iam::585008076257:role/ebs-csi-irsa-role --overwrite
```

## Atualizar o Terraform (`irsa.tf`)

Após a criação do novo OIDC Provider, é necessário **referenciá-lo manualmente no Terraform**, já que ele **não será gerenciado diretamente pelo Terraform**.

### Bloco Terraform atualizado (`irsa.tf e csi.tf`) em FEDERATED:

### irsa.tf
```hcl
resource "aws_iam_role" "irsa_sqs_role" {
  name = "notificacao-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/" = "system:serviceaccount:fast-video:notificacao-api-sa",
            "oidc.eks.us-east-1.amazonaws.com/id/7" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

```

### csi.tf

```hcl
resource "aws_iam_role" "ebs_csi_irsa_role" {
  name = "ebs-csi-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::<account_id>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/<oicd>"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/<oicd>:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "oidc.eks.us-east-1.amazonaws.com/id/<oicd>:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}
```hcl

> ⚠️ **Substitua o ID do OIDC pelo atual**, que pode ser verificado com:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name video-processor-eks-cluster \
  --query "cluster.identity.oidc.issuer" \
  --output text
```
## INSTALL DAPR

```BASH
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

helm install dapr dapr/dapr --namespace dapr-system --create-namespace
```

---

## Aplicar Terraform

Após editar o `irsa.tf`:

```bash
terraform init
terraform apply
```

---

## Criar o `ServiceAccount` com anotação IRSA

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: notificacao-api-sa
  namespace: fast-video
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::585008076257:role/notificacao-api-irsa-role
```

Aplique com:

```bash
kubectl apply -f serviceaccount.yaml
```

---

## Garantir que o pod está usando o `ServiceAccount`

No `Deployment` da sua aplicação:

```yaml
spec:
  serviceAccountName: notificacao-api-sa
```

Depois, reinicie o pod:

```bash
kubectl rollout restart deployment notificacao-api -n fast-video
```

---

## Validação final

Execute:

```bash
kubectl exec -it <pod-name> -n fast-video -- env | grep AWS
```


```
AWS_ROLE_ARN=arn:aws:iam::585008076257:role/notificacao-api-irsa-role
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```
