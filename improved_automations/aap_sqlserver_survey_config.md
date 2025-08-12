# Configuração do Survey no AAP para Gerenciamento de Usuários SQL Server

Este guia explica como configurar o Survey no Ansible Automation Platform para usar a automação `03_manage_sqlserver_users_aap.yml`.

## Configuração do Job Template

### 1. Informações Básicas
- **Nome**: `Manage SQL Server Users`
- **Descrição**: `Criação e gerenciamento de usuários SQL Server com perfis de acesso`
- **Playbook**: `03_manage_sqlserver_users_aap.yml`
- **Inventário**: `Windows Database Servers`
- **Credencial de Máquina**: `windows-admin`
- **Credencial de Vault**: `sqlserver-secrets`

### 2. Configuração do Survey

#### Variáveis Obrigatórias

```yaml
# Nome do usuário
username:
  type: text
  required: true
  help_text: "Nome do usuário SQL Server a ser criado"

# Senha do usuário
user_password:
  type: password
  required: true
  help_text: "Senha do usuário SQL Server"

# Instância SQL Server
sql_server_instance:
  type: text
  required: false
  default: "MSSQLSERVER"
  help_text: "Nome da instância SQL Server"

# Banco de dados principal
target_database:
  type: text
  required: true
  default: "master"
  help_text: "Nome do banco de dados principal"

# Schema principal
target_schema:
  type: text
  required: false
  default: "dbo"
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

# Login habilitado
login_enabled:
  type: boolean
  required: false
  default: true
  help_text: "Habilitar o login do usuário"

# Policy de senha
password_policy:
  type: boolean
  required: false
  default: true
  help_text: "Aplicar política de senha do Windows"

# Expiração de senha
password_expiration:
  type: boolean
  required: false
  default: false
  help_text: "Habilitar expiração de senha"

# Banco padrão
default_database:
  type: text
  required: false
  default: "master"
  help_text: "Banco de dados padrão do usuário"
```

#### Variáveis Opcionais

```yaml
# Apenas criar usuário (sem privilégios)
create_user_only:
  type: boolean
  required: false
  default: false
  help_text: "Apenas criar o login, sem conceder privilégios"

# Atualizar usuário existente
update_existing:
  type: boolean
  required: false
  default: true
  help_text: "Atualizar senha e configurações de login existente"

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
      {"name": "app2", "schema": "dbo"},
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
target_schema: dbo
profile: readonly
login_enabled: true
password_policy: true
default_database: app1
add_comment: "Usuário para relatórios e consultas"
```

### 2. Usuário de Aplicação
```yaml
username: app_user
user_password: "{{ vault_app_password }}"
target_database: app1
target_schema: dbo
profile: readwrite
login_enabled: true
password_policy: true
password_expiration: false
default_database: app1
additional_databases: |
  [
    {"name": "app2", "schema": "dbo"},
    {"name": "financeiro", "schema": "finance"}
  ]
add_comment: "Usuário da aplicação principal"
```

### 3. Usuário Administrador
```yaml
username: admin_user
user_password: "{{ vault_admin_password }}"
target_database: app1
target_schema: dbo
profile: dbadmin
login_enabled: true
password_policy: true
password_expiration: true
default_database: app1
additional_schemas: |
  [
    {"name": "admin"},
    {"name": "audit"}
  ]
add_comment: "Usuário administrador do banco"
```

### 4. Apenas Criar Login
```yaml
username: temp_user
user_password: "{{ vault_temp_password }}"
target_database: master
create_user_only: true
add_comment: "Login temporário para migração"
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

### Credencial de Máquina Windows
- **Tipo**: Machine
- **Usuário**: `Administrator` (ou usuário com privilégios)
- **Senha**: [senha do usuário]
- **Privilégios de Escalação**: Habilitado
- **Método de Escalação**: runas

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

## Pré-requisitos do SQL Server

### Módulos PowerShell Necessários
```powershell
# Instalar módulo SqlServer
Install-Module -Name SqlServer -Force -AllowClobber

# Verificar instalação
Get-Module -Name SqlServer -ListAvailable
```

### Configurações do SQL Server
```sql
-- Habilitar autenticação mista
EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE', 
    N'Software\Microsoft\MSSQLServer\MSSQLServer', 
    N'LoginMode', 
    REG_DWORD, 
    2;

-- Reiniciar SQL Server
RESTART;
```

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
- Login criado/atualizado
- Perfil aplicado
- Privilégios concedidos
- Timestamp da operação
- Usuário que executou

## Troubleshooting

### Problemas Comuns

1. **Erro de Permissão**
   - Verificar se a credencial tem privilégios de administrador
   - Confirmar acesso ao SQL Server

2. **Erro de Conexão**
   - Verificar se SQL Server está rodando
   - Confirmar porta 1433 acessível
   - Verificar se autenticação mista está habilitada

3. **Erro de Módulo PowerShell**
   - Verificar se módulo SqlServer está instalado
   - Executar: `Import-Module SqlServer`

4. **Erro de Vault**
   - Verificar se credencial de vault está configurada
   - Confirmar variáveis definidas

5. **Erro de Schema**
   - Verificar se schema existe
   - Confirmar permissões no schema

### Logs de Debug
Para debug detalhado, adicione ao job template:
```yaml
ansible_verbosity: 4
ansible_debug: true
```

### Verificação Manual
```powershell
# Verificar logins
SELECT name, type_desc, is_disabled, default_database_name 
FROM sys.server_principals 
WHERE type = 'S';

# Verificar usuários em banco específico
USE [app1];
SELECT dp.name AS DatabaseRoleName, mp.name AS DatabaseUserName
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON dp.principal_id = drm.role_principal_id
JOIN sys.database_principals mp ON mp.principal_id = drm.member_principal_id
WHERE mp.name = 'app_user';
```

## Integração com Workflows

### Workflow: Deploy SQL Server User Environment
1. **ServiceNow - Criar Mudança**
2. **Validar SQL Server Acessível**
3. **Criar Usuário SQL Server**
4. **Testar Conexão**
5. **ServiceNow - Fechar Mudança**

### Workflow: SQL Server User Lifecycle Management
1. **Criar Login SQL Server**
2. **Configurar Monitoramento**
3. **Agendar Revisão**
4. **Notificar Stakeholders**

## Comparação com PostgreSQL

| Aspecto | PostgreSQL | SQL Server |
|---------|------------|------------|
| **Tipo de Login** | Role | Login + User |
| **Perfis** | readonly, readwrite, dbadmin | readonly, readwrite, dbadmin |
| **Roles** | CONNECT, USAGE, SELECT, etc. | db_datareader, db_datawriter, db_owner |
| **Schemas** | GRANT ON SCHEMA | GRANT ON SCHEMA:: |
| **Default Privileges** | ALTER DEFAULT PRIVILEGES | Não aplicável |
| **Validação** | VALID UNTIL | Password Expiration |
| **Connection Limit** | CONNECTION LIMIT | Não aplicável |
