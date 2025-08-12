# Integração com Ansible Automation Platform (AAP)

Este guia explica como configurar e executar as automações de banco de dados no Ansible Automation Platform.

## Pré-requisitos

### 1. Collections Necessárias
Instale as collections necessárias no AAP:

```bash
# Via linha de comando do AAP
ansible-galaxy collection install servicenow.itsm
ansible-galaxy collection install community.postgresql
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install ansible.utils
```

Ou use o arquivo `collections/requirements.yml`:
```bash
ansible-galaxy collection install -r collections/requirements.yml
```

### 2. Credenciais no AAP
Configure as seguintes credenciais no AAP:

#### Credenciais de Máquina
- **Tipo**: Machine
- **Nome**: `postgresql-admin`
- **Usuário**: `ansible` (ou usuário com sudo)
- **Senha**: [senha do usuário]
- **Privilégios de Escalação**: Habilitado
- **Método de Escalação**: sudo

#### Credenciais de Vault
- **Tipo**: Vault
- **Nome**: `database-secrets`
- **Conteúdo**:
```yaml
vault_app_user_password: "SenhaApp123!"
vault_readonly_user_password: "ReadOnly123!"
vault_admin_user_password: "Admin123!"
vault_snow_password: "snow_password"
vault_smtp_username: "smtp_user"
vault_smtp_password: "smtp_password"
```

#### Credenciais do ServiceNow (se aplicável)
- **Tipo**: ServiceNow
- **Nome**: `servicenow-integration`
- **URL**: `https://your-instance.service-now.com`
- **Usuário**: `ansible_user`
- **Senha**: [senha do ServiceNow]

## Configuração no AAP

### 1. Inventário
Crie um inventário no AAP com os hosts dos servidores de banco de dados:

```yaml
# Exemplo de inventário para AAP
all:
  children:
    db_servers:
      hosts:
        db-server-01:
          ansible_host: 192.168.1.10
        db-server-02:
          ansible_host: 192.168.1.11
        db-server-03:
          ansible_host: 192.168.1.12
      vars:
        pg_user: "postgres"
        pg_port: 5432
        pg_data_dir: "/var/lib/pgsql/data"
```

### 2. Projetos
Crie um projeto no AAP apontando para este repositório:

- **Nome**: `Database Automations`
- **Tipo de SCM**: Git
- **URL do SCM**: [URL do seu repositório]
- **Branch**: `main`
- **Caminho do Projeto**: `improved_automations`

### 3. Job Templates

#### Job Template: Instalar PostgreSQL
- **Nome**: `Install PostgreSQL`
- **Projeto**: `Database Automations`
- **Playbook**: `01_install_postgresql.yml`
- **Inventário**: `Database Servers`
- **Credencial de Máquina**: `postgresql-admin`
- **Credencial de Vault**: `database-secrets`
- **Opções**:
  - ✅ Habilitar Privilégios de Escalação
  - ✅ Habilitar Verbosidade
  - ✅ Habilitar Dry Run

#### Job Template: Gerenciar Usuários
- **Nome**: `Manage Database Users`
- **Projeto**: `Database Automations`
- **Playbook**: `03_manage_users.yml`
- **Inventário**: `Database Servers`
- **Credencial de Máquina**: `postgresql-admin`
- **Credencial de Vault**: `database-secrets`
- **Variáveis Extra**:
```yaml
db_users:
  - username: "{{ username }}"
    password: "{{ password }}"
    profile: "{{ profile }}"
    databases: "{{ databases }}"
    schemas: "{{ schemas }}"
```

#### Job Template: Health Check
- **Nome**: `Database Health Check`
- **Projeto**: `Database Automations`
- **Playbook**: `06_health_check.yml`
- **Inventário**: `Database Servers`
- **Credencial de Máquina**: `postgresql-admin`
- **Opções**:
  - ✅ Habilitar Verbosidade

#### Job Template: ServiceNow Integration
- **Nome**: `ServiceNow Change Management`
- **Projeto**: `Database Automations`
- **Playbook**: `10_servicenow_integration.yml`
- **Inventário**: `localhost`
- **Credencial do ServiceNow**: `servicenow-integration`
- **Variáveis Extra**:
```yaml
change_operation: "{{ change_operation }}"
change_short_description: "{{ change_description }}"
change_impact: "{{ change_impact }}"
change_urgency: "{{ change_urgency }}"
```

### 4. Workflows

#### Workflow: Deploy Database Environment
Crie um workflow que combine múltiplos job templates:

1. **ServiceNow - Criar Mudança**
   - Job Template: `ServiceNow Change Management`
   - Variáveis: `change_operation: create`

2. **Instalar PostgreSQL**
   - Job Template: `Install PostgreSQL`
   - Condição: Sucesso do passo anterior

3. **Criar Bancos de Dados**
   - Job Template: `Manage Databases`
   - Condição: Sucesso do passo anterior

4. **Criar Usuários**
   - Job Template: `Manage Database Users`
   - Condição: Sucesso do passo anterior

5. **Health Check**
   - Job Template: `Database Health Check`
   - Condição: Sucesso do passo anterior

6. **ServiceNow - Fechar Mudança**
   - Job Template: `ServiceNow Change Management`
   - Variáveis: `change_operation: close`
   - Condição: Sucesso do passo anterior

## Execução via API

### Exemplo de chamada API para executar job template:

```bash
curl -X POST \
  https://your-aap-instance/api/v2/job_templates/1/launch/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "pg_version": "15",
      "pg_max_connections": 200,
      "db_users": [
        {
          "username": "app_user",
          "password": "{{ vault_app_user_password }}",
          "profile": "readwrite",
          "databases": ["app1", "app2"]
        }
      ]
    }
  }'
```

## Monitoramento e Logs

### 1. Logs de Execução
- Acesse os logs detalhados no AAP via interface web
- Configure notificações por email para falhas
- Use o callback `timer` para monitorar tempo de execução

### 2. Métricas de Performance
- Configure o callback `profile_tasks` para análise de performance
- Monitore o tempo de execução de cada playbook
- Configure alertas para execuções que excedam o tempo esperado

### 3. Relatórios
- Use o módulo `set_stats` para coletar métricas
- Configure dashboards no AAP para visualizar resultados
- Exporte relatórios via API do AAP

## Troubleshooting

### Problemas Comuns

1. **Erro de Permissão**
   - Verifique se a credencial de máquina tem sudo
   - Confirme se o usuário pode executar comandos PostgreSQL

2. **Erro de Conexão**
   - Verifique se o PostgreSQL está rodando
   - Confirme se a porta 5432 está acessível
   - Teste conectividade manualmente

3. **Erro de Vault**
   - Verifique se a credencial de vault está configurada
   - Confirme se as variáveis estão definidas corretamente

4. **Erro de Collection**
   - Instale as collections necessárias
   - Verifique a versão das collections

### Logs de Debug
Para debug detalhado, adicione estas variáveis ao job template:
```yaml
ansible_verbosity: 4
ansible_debug: true
```

## Segurança

### 1. Controle de Acesso
- Configure RBAC no AAP para limitar acesso aos job templates
- Use credenciais de vault para senhas sensíveis
- Implemente auditoria de execuções

### 2. Validação de Entrada
- Use `vars_prompt` para validação interativa
- Implemente validação de variáveis com `assert`
- Configure limites de execução

### 3. Rollback
- Implemente playbooks de rollback
- Configure backups automáticos antes de mudanças
- Use tags para execução seletiva

## Exemplos de Uso

### Execução via Interface Web
1. Acesse o AAP
2. Vá para "Templates"
3. Selecione o job template desejado
4. Clique em "Launch"
5. Configure as variáveis necessárias
6. Execute

### Execução via CLI
```bash
# Via tower-cli (se disponível)
tower-cli job launch --job-template="Install PostgreSQL" --extra-vars="pg_version=15"

# Via ansible-runner
ansible-runner run . -p 01_install_postgresql.yml -i inventory/hosts.yml
```

### Execução via GitOps
Configure webhooks no repositório para executar automaticamente quando houver mudanças em branches específicos.
