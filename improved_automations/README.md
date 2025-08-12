# Automações de Banco de Dados - Versões Melhoradas

Este diretório contém versões melhoradas e consolidadas das automações de banco de dados PostgreSQL, seguindo as melhores práticas do Ansible.

## Estrutura dos Arquivos

### 1. Instalação e Configuração
- `01_install_postgresql.yml` - Instalação completa do PostgreSQL com configurações otimizadas
- `02_configure_postgresql.yml` - Configuração avançada do PostgreSQL (HBA, parâmetros, etc.)

### 2. Gerenciamento de Usuários e Bancos
- `03_manage_users.yml` - Criação e gerenciamento de usuários com perfis de acesso
- `04_manage_databases.yml` - Criação e configuração de bancos de dados
- `05_populate_database.yml` - População de bancos com dados de exemplo

### 3. Monitoramento e Health Check
- `06_health_check.yml` - Health check completo do PostgreSQL e sistema
- `07_monitoring_setup.yml` - Configuração de monitoramento e alertas

### 4. Operações de Manutenção
- `08_maintenance_tasks.yml` - Tarefas de manutenção (vacuum, analyze, backup)
- `09_backup_restore.yml` - Backup e restauração de bancos

### 5. Integração com ServiceNow
- `10_servicenow_integration.yml` - Integração com ServiceNow para mudanças

### 6. Utilitários
- `11_database_utilities.yml` - Utilitários para consultas e operações no banco
- `12_security_hardening.yml` - Hardening de segurança do PostgreSQL

## Melhorias Implementadas

### 1. Consolidação de Versões
- Unificação de arquivos duplicados (health_check_v1, v2, v3 → health_check.yml)
- Consolidação de criação de usuários (user.yml, create_db_user_aap_v1, v2 → manage_users.yml)

### 2. Melhores Práticas
- Uso de `ansible.builtin` para módulos nativos
- Implementação de handlers para reinicialização de serviços
- Validação de entrada com `vars_prompt` e `vars_files`
- Tratamento de erros com `failed_when` e `ignore_errors`
- Uso de `no_log: true` para senhas e dados sensíveis

### 3. Segurança
- Hardening automático do PostgreSQL
- Configuração segura do pg_hba.conf
- Validação de senhas fortes
- Controle de acesso baseado em perfis

### 4. Monitoramento
- Health check abrangente (sistema + banco)
- Coleta de métricas de performance
- Detecção de problemas comuns
- Relatórios em JSON e HTML

### 5. Flexibilidade
- Suporte a múltiplos ambientes (dev, staging, prod)
- Configuração via variáveis de ambiente
- Integração com AAP (Ansible Automation Platform)
- Suporte a diferentes versões do PostgreSQL

## Como Usar

### Execução Básica
```bash
# Instalar PostgreSQL
ansible-playbook 01_install_postgresql.yml

# Criar usuários
ansible-playbook 03_manage_users.yml

# Health check
ansible-playbook 06_health_check.yml
```

### Com Variáveis Customizadas
```bash
# Usar arquivo de variáveis
ansible-playbook 03_manage_users.yml -e @vars/production.yml

# Com variáveis inline
ansible-playbook 03_manage_users.yml -e "db_username=app_user db_password=secure123"
```

### Com Tags
```bash
# Apenas instalação
ansible-playbook 01_install_postgresql.yml --tags install

# Apenas configuração
ansible-playbook 02_configure_postgresql.yml --tags config
```

## Variáveis Importantes

### Configuração do Banco
- `pg_version`: Versão do PostgreSQL
- `pg_data_dir`: Diretório de dados
- `pg_port`: Porta do PostgreSQL
- `pg_max_connections`: Máximo de conexões

### Usuários e Bancos
- `db_users`: Lista de usuários a criar
- `db_databases`: Lista de bancos a criar
- `access_profiles`: Perfis de acesso (readonly, readwrite, admin)

### Monitoramento
- `monitoring_enabled`: Habilitar monitoramento
- `alert_email`: Email para alertas
- `health_check_interval`: Intervalo do health check

## Requisitos

- Ansible 2.9+
- Python 3.6+
- Acesso root/sudo nos servidores
- PostgreSQL 10+ (para algumas funcionalidades)

## Contribuição

Para contribuir com melhorias:
1. Teste as automações em ambiente de desenvolvimento
2. Documente as mudanças
3. Mantenha compatibilidade com versões anteriores
4. Siga as convenções de nomenclatura
