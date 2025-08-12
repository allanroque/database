#!/bin/bash

# Script para facilitar a execução das automações de banco de dados
# Uso: ./run_automation.sh <operação> [opções]

set -e

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir ajuda
show_help() {
    echo -e "${BLUE}Automações de Banco de Dados PostgreSQL${NC}"
    echo ""
    echo "Uso: $0 <operação> [opções]"
    echo ""
    echo "Operações disponíveis:"
    echo "  install          - Instalar PostgreSQL"
    echo "  configure        - Configurar PostgreSQL"
    echo "  users            - Gerenciar usuários"
    echo "  databases        - Gerenciar bancos de dados"
    echo "  populate         - Popular bancos com dados"
    echo "  health-check     - Executar health check"
    echo "  monitoring       - Configurar monitoramento"
    echo "  maintenance      - Executar manutenção"
    echo "  backup           - Fazer backup"
    echo "  restore          - Restaurar backup"
    echo "  servicenow       - Integração com ServiceNow"
    echo "  utilities        - Utilitários do banco"
    echo "  security         - Hardening de segurança"
    echo ""
    echo "Opções:"
    echo "  -i, --inventory <arquivo>  - Arquivo de inventário"
    echo "  -e, --extra-vars <arquivo> - Arquivo de variáveis extras"
    echo "  -t, --tags <tags>          - Tags específicas"
    echo "  -v, --verbose              - Modo verboso"
    echo "  -d, --dry-run              - Modo dry-run"
    echo "  -h, --help                 - Exibir esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 install -i inventory/hosts.yml"
    echo "  $0 users -e vars/production.yml"
    echo "  $0 health-check --tags quick"
    echo "  $0 backup -e vars/backup.yml"
}

# Função para exibir erro
error() {
    echo -e "${RED}Erro: $1${NC}" >&2
    exit 1
}

# Função para exibir sucesso
success() {
    echo -e "${GREEN}Sucesso: $1${NC}"
}

# Função para exibir aviso
warning() {
    echo -e "${YELLOW}Aviso: $1${NC}"
}

# Função para exibir informação
info() {
    echo -e "${BLUE}Info: $1${NC}"
}

# Variáveis padrão
OPERATION=""
INVENTORY="inventory/hosts.yml"
EXTRA_VARS=""
TAGS=""
VERBOSE=""
DRY_RUN=""

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        install|configure|users|databases|populate|health-check|monitoring|maintenance|backup|restore|servicenow|utilities|security)
            OPERATION="$1"
            shift
            ;;
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -e|--extra-vars)
            EXTRA_VARS="$2"
            shift 2
            ;;
        -t|--tags)
            TAGS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="-v"
            shift
            ;;
        -d|--dry-run)
            DRY_RUN="--check"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1"
            ;;
    esac
done

# Verificar se a operação foi especificada
if [[ -z "$OPERATION" ]]; then
    error "Operação não especificada. Use -h para ver as opções disponíveis."
fi

# Verificar se o arquivo de inventário existe
if [[ ! -f "$INVENTORY" ]]; then
    error "Arquivo de inventário não encontrado: $INVENTORY"
fi

# Verificar se o arquivo de variáveis extras existe (se especificado)
if [[ -n "$EXTRA_VARS" && ! -f "$EXTRA_VARS" ]]; then
    error "Arquivo de variáveis extras não encontrado: $EXTRA_VARS"
fi

# Mapear operações para arquivos de playbook
case $OPERATION in
    install)
        PLAYBOOK="01_install_postgresql.yml"
        ;;
    configure)
        PLAYBOOK="02_configure_postgresql.yml"
        ;;
    users)
        PLAYBOOK="03_manage_users.yml"
        ;;
    databases)
        PLAYBOOK="04_manage_databases.yml"
        ;;
    populate)
        PLAYBOOK="05_populate_database.yml"
        ;;
    health-check)
        PLAYBOOK="06_health_check.yml"
        ;;
    monitoring)
        PLAYBOOK="07_monitoring_setup.yml"
        ;;
    maintenance)
        PLAYBOOK="08_maintenance_tasks.yml"
        ;;
    backup)
        PLAYBOOK="09_backup_restore.yml"
        ;;
    restore)
        PLAYBOOK="09_backup_restore.yml"
        ;;
    servicenow)
        PLAYBOOK="10_servicenow_integration.yml"
        ;;
    utilities)
        PLAYBOOK="11_database_utilities.yml"
        ;;
    security)
        PLAYBOOK="12_security_hardening.yml"
        ;;
    *)
        error "Operação desconhecida: $OPERATION"
        ;;
esac

# Verificar se o playbook existe
if [[ ! -f "$PLAYBOOK" ]]; then
    error "Playbook não encontrado: $PLAYBOOK"
fi

# Construir comando do Ansible
ANSIBLE_CMD="ansible-playbook $PLAYBOOK -i $INVENTORY"

# Adicionar variáveis extras se especificadas
if [[ -n "$EXTRA_VARS" ]]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e @$EXTRA_VARS"
fi

# Adicionar tags se especificadas
if [[ -n "$TAGS" ]]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --tags $TAGS"
fi

# Adicionar opções de verbosidade e dry-run
if [[ -n "$VERBOSE" ]]; then
    ANSIBLE_CMD="$ANSIBLE_CMD $VERBOSE"
fi

if [[ -n "$DRY_RUN" ]]; then
    ANSIBLE_CMD="$ANSIBLE_CMD $DRY_RUN"
fi

# Exibir informações da execução
info "Executando operação: $OPERATION"
info "Playbook: $PLAYBOOK"
info "Inventário: $INVENTORY"
if [[ -n "$EXTRA_VARS" ]]; then
    info "Variáveis extras: $EXTRA_VARS"
fi
if [[ -n "$TAGS" ]]; then
    info "Tags: $TAGS"
fi
if [[ -n "$DRY_RUN" ]]; then
    warning "Modo dry-run ativado"
fi
echo ""

# Executar comando
info "Executando: $ANSIBLE_CMD"
echo ""

if eval $ANSIBLE_CMD; then
    success "Operação $OPERATION concluída com sucesso!"
else
    error "Operação $OPERATION falhou!"
fi
