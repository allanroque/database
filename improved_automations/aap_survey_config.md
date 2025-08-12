# Configuração do Survey no AAP para Gerenciamento de Usuários PostgreSQL

Este guia explica como configurar o Survey no Ansible Automation Platform para usar a automação `03_manage_users_aap.yml`.

## Configuração do Job Template

### 1. Informações Básicas
- **Nome**: `Manage PostgreSQL Users`
- **Descrição**: `Criação e gerenciamento de usuários PostgreSQL com perfis de acesso`
- **Playbook**: `03_manage_users_aap.yml`
- **Inventário**: `Database Servers`
- **Credencial de Máquina**: `postgresql-admin`
- **Credencial de Vault**: `database-secrets`

### 2. Configuração do Survey

#### Variáveis Obrigatórias

```yaml
# Nome do usuário
username:
  type: text
  required: true
  help_text: "Nome do usuário PostgreSQL a ser criado"

# Senha do usuário
user_password:
  type: password
  required: true
  help_text: "Senha do usuário PostgreSQL"

# Banco de dados principal
target_database:
  type: text
  required: true
  default: "postgres"
  help_text: "Nome do banco de dados principal"

# Schema principal
target_schema:
  type: text
  required: false
  default: "public"
  help_text: "Nome do schema principal"
```

#### Variáveis de Perfil

```yaml
# Perfil de acesso
profile:
  type: choice
  required: false
  default: "readonly"
  choices:
    - readonly
    - readwrite
    - dbadmin
  help_text: "Perfil de acesso do usuário"

# Limite de conexões
conn_limit:
  type: integer
  required: false
  default: 10
  min: 1
  max: 100
  help_text: "Limite de conexões simultâneas"

# Timeout de statements
stmt_timeout:
  type: text
  required: false
  default: "5min"
  help_text: "Timeout para execução de statements (ex: 5min, 1h)"

# Data de validade
valid_until:
  type: text
  required: false
  default: "infinity"
  help_text: "Data de validade do usuário (ex: 2025-12-31, infinity)"

# Search path
search_path:
  type: text
  required: false
  default: "public"
  help_text: "Search path padrão do usuário"
```

#### Variáveis Opcionais

```yaml
# Apenas criar usuário (sem privilégios)
create_user_only:
  type: boolean
  required: false
  default: false
  help_text: "Apenas criar o usuário, sem conceder privilégios"

# Atualizar usuário existente
update_existing:
  type: boolean
  required: false
  default: true
  help_text: "Atualizar senha e configurações de usuário existente"

# Comentário do usuário
add_comment:
  type: textarea
  required: false
  help_text: "Comentário descritivo do usuário"
```

#### Variáveis Avançadas (JSON)

```yaml
# Bancos adicionais
additional_databases:
  type: textarea
  required: false
  help_text: |
    Lista de bancos adicionais em formato JSON:
    [
      {"name": "app2", "schema": "public"},
      {"name": "financeiro", "schema": "finance"}
    ]

# Schemas adicionais
additional_schemas:
  type: textarea
  required: false
  help_text: |
    Lista de schemas adicionais em formato JSON:
    [
      {"name": "app"},
      {"name": "admin"}
    ]
```

## Exemplos de Uso

### 1. Usuário Somente Leitura
```yaml
username: readonly_user
user_password: "{{ vault_readonly_password }}"
target_database: app1
target_schema: public
profile: readonly
conn_limit: 5
stmt_timeout: 5min
add_comment: "Usuário para relatórios e consultas"
```

### 2. Usuário de Aplicação
```yaml
username: app_user
user_password: "{{ vault_app_password }}"
target_database: app1
target_schema: public
profile: readwrite
conn_limit: 20
stmt_timeout: 10min
valid_until: 2025-12-31
additional_databases: |
  [
    {"name": "app2", "schema": "public"},
    {"name": "financeiro", "schema": "finance"}
  ]
add_comment: "Usuário da aplicação principal"
```

### 3. Usuário Administrador
```yaml
username: admin_user
user_password: "{{ vault_admin_password }}"
target_database: app1
target_schema: public
profile: dbadmin
conn_limit: 50
stmt_timeout: 30min
additional_schemas: |
  [
    {"name": "admin"},
    {"name": "audit"}
  ]
add_comment: "Usuário administrador do banco"
```

### 4. Apenas Criar Usuário
```yaml
username: temp_user
user_password: "{{ vault_temp_password }}"
target_database: postgres
create_user_only: true
add_comment: "Usuário temporário para migração"
```

## Configuração de Credenciais

### Credencial de Vault
Crie uma credencial de vault com as seguintes variáveis:
```yaml
vault_readonly_password: "ReadOnly123!"
vault_app_password: "AppUser123!"
vault_admin_password: "Admin123!"
vault_temp_password: "Temp123!"
```

### Credencial de Máquina
- **Tipo**: Machine
- **Usuário**: `ansible` (ou usuário com sudo)
- **Senha**: [senha do usuário]
- **Privilégios de Escalação**: Habilitado
- **Método de Escalação**: sudo

## Configuração de Permissões

### RBAC no AAP
Configure as seguintes permissões:
- **Usuários de Desenvolvimento**: Apenas `readonly` e `readwrite`
- **DBAs**: Todos os perfis incluindo `dbadmin`
- **Auditores**: Apenas visualização de logs

### Limitações de Execução
- **Timeout**: 300 segundos
- **Concurrent Jobs**: Máximo 2 por servidor
- **Approval**: Necessário para perfis `dbadmin`

## Monitoramento e Logs

### Configuração de Notificações
```yaml
# Notificar em caso de sucesso
notify_on_success: true
success_email: "dba@company.com"

# Notificar em caso de falha
notify_on_failure: true
failure_email: "dba@company.com,admin@company.com"

# Notificar para perfis admin
notify_admin_operations: true
admin_email: "admin@company.com"
```

### Logs de Auditoria
A automação registra automaticamente:
- Usuário criado/atualizado
- Perfil aplicado
- Privilégios concedidos
- Timestamp da operação
- Usuário que executou

## Troubleshooting

### Problemas Comuns

1. **Erro de Permissão**
   - Verificar se a credencial tem sudo
   - Confirmar acesso ao PostgreSQL

2. **Erro de Conexão**
   - Verificar se PostgreSQL está rodando
   - Confirmar porta 5432 acessível

3. **Erro de Vault**
   - Verificar se credencial de vault está configurada
   - Confirmar variáveis definidas

4. **Erro de Schema**
   - Verificar se schema existe
   - Confirmar permissões no schema

### Logs de Debug
Para debug detalhado, adicione ao job template:
```yaml
ansible_verbosity: 4
ansible_debug: true
```

## Integração com Workflows

### Workflow: Deploy User Environment
1. **ServiceNow - Criar Mudança**
2. **Validar Banco Existe**
3. **Criar Usuário PostgreSQL**
4. **Testar Conexão**
5. **ServiceNow - Fechar Mudança**

### Workflow: User Lifecycle Management
1. **Criar Usuário**
2. **Configurar Monitoramento**
3. **Agendar Revisão**
4. **Notificar Stakeholders**
