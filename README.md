# Infraestrutura Web na AWS com Monitoramento Automatizado 

Este projeto foi desenvolvido como parte de um programa de bolsas em DevSecOps e tem como objetivo principal levantar uma infraestrutura web básica, segura e funcional na Amazon Web Services (AWS), garantindo a disponibilidade contínua de um website. A solução inclui a configuração de rede, a implantação de um servidor web (Nginx) para hospedar uma página HTML, e a implementação de um sistema de monitoramento automatizado com alertas. 

## Tecnologias Utilizadas

* AWS (Amazon Web Services): Plataforma de computação em nuvem utilizada para provisionar e gerenciar a infraestrutura do projeto.

* Ubuntu Server: Sistema operacional Linux escolhido para a instância EC2 na AWS, onde o servidor web Nginx e os scripts de monitoramento foram configurados.

* Nginx: Servidor web de alto desempenho responsável por hospedar a página HTML, atuando como a "fachada" inicial da aplicação. 

* WSL (Windows Subsystem for Linux): Utilizado como ambiente de desenvolvimento local para executar comandos Linux e interagir via SSH com a instância EC2.

* Discord: Serviço de comunicação empregado para o envio de notificações de indisponibilidade do site através de webhooks, emitindo alertas em tempo real. 

* Bash: Linguagem de script utilizada para desenvolver o monitoramento automatizado da aplicação.

## Dependências e Versões Necessárias

* Sistema Operacional da EC2: Ubuntu 24.04.2 LTS.

* Servidor Web: nginx/1.24.0 (Ubuntu). 

* Utilitário de Requisição HTTP: curl - 8.5.0. 

* Agendador de Tarefas: cron (para a execução automática do script de monitoramento a cada minuto).

## Etapa 1: Configuração do Ambiente

### 1.1. Configuração da Rede na AWS Console

* **Criação da VPC "projeto-Linux"**: Uma Virtual Private Cloud (VPC) personalizada nomeada "projeto-Linux" foi criada, servindo como a rede isolada para a infraestrutura.
* **Criação de Sub-redes**: Dentro da VPC "projeto-Linux", foram configuradas as seguintes sub-redes:
    * Duas sub-redes públicas: `subrede-publica01` e `subrede-publica02`.
    * Duas sub-redes privadas: `subrede-privada01` e `subrede-privada02`.

### 1.2. Configuração da Instância EC2 na AWS Console

* **Lançamento da Instância EC2**: Uma instância EC2 (distribuição Ubuntu 24.04 LTS) foi lançada **na `subrede-publica01`** através do console da AWS.
* **Geração e Salvamento da Chave SSH**: Durante o processo de lançamento, um novo par de chaves SSH (`projetoLinux.pem`) foi gerado e salvo localmente para permitir acesso seguro à instância via SSH.
* **Configuração do Grupo de Segurança (MeuGrupoDeSegurança)**: Um novo Grupo de Segurança foi criado e configurado com as seguintes regras de entrada (`Inbound Rules`):
    * **SSH (Porta TCP 22)**: Permitido para o endereço IP `<IP_AUTORIZADO_LOCAL>/32` (ex: `143.202.111.53/32` no formato CIDR).
    * **HTTP (Porta TCP 80)**: Permitido para `0.0.0.0/0` (acesso de qualquer IP na internet).
    * As regras de saída (`Outbound Rules`) foram mantidas como padrão (permitindo todo o tráfego para `0.0.0.0/0`).
* **Associação do Grupo de Segurança à Instância**: O Grupo de Segurança criado (`MeuGrupoDeSegurança`) foi associado à instância EC2, garantindo que as regras de firewall definidas fossem aplicadas corretamente ao tráfego de rede da instância.

### 1.3. Conexão à Instância EC2 via SSH 

Para acessar o terminal da instância EC2 a partir do ambiente local (WSL), foi utilizado o seguinte comando (substituindo o caminho da chave e o IP público da instância por dados reais): 

```
ssh -i <CAMINHO_DA_CHAVE>/projetoLinux.pem ubuntu@<IP_PUBLICO_DA_EC2>
```

## Etapa 2: Configuração do Servidor Web

### 2.1. Instalação e Verificação do Nginx na Instância EC2 

Com a instância EC2 conectada, foram usados os seguintes comandos: 

* **Atualizar a lista de pacotes do sistema**:
```
sudo apt update
```

* **Instalar o servidor web Nginx**:
```
sudo apt install nginx -y
```

* **Verificar o status do serviço Nginx**:
```
sudo systemctl status nginx
```
* Neste comando a saída esperada é active (running), indicando que o Nginx está em execução.

* **Verificar se o Nginx está escutando na porta 80**:
```
sudo ss -tuln | grep 80
```
* A saída aqui deve mostrar uma linha indicando que o Nginx está ouvindo conexões na porta 80 em todas as interfaces de rede (ex: LISTEN 0.0.0.0:80 ou LISTEN :::80 para IPv6).

### 2.2. Implantação da Página Web Personalizada

Com o servidor Nginx instalado e funcionando, foram usados os seguintes comandos para substituir a página de boas-vindas padrão do Nginx pela página desejada (contendo HTML, CSS, JavaScript e imagens): 

* **Navegar para o diretório da página no ambiente local (WSL)**:
```
exit --> para voltar ao WSL
cd /caminho/da/pasta/onde/esta/a/pagina/
```
* Se a pasta do projeto estivesse localizada em C:\Users\Usuario\Documentos no Windows, por exemplo, o comando usado no WSL seria:
```
cd /mnt/c/Users/Usuario/Documentos/
```
* **Copiar o diretório do projeto para a instância EC2 usando scp**:
```
scp -i <CAMINHO_DA_CHAVE>/chave.pem -r nome-da-pasta-da-pagina ubuntu@<IP_PUBLICO_DA_INSTANCIA>:/tmp/
```
* Este comando copia recursivamente (-r) toda a pasta nome-da-pasta-da-pagina para o diretório temporário /tmp/ na instância EC2.

* **Conectar-se novamente à instância EC2 via SSH**:
```
ssh -i <CAMINHO_DA_CHAVE>/projetoLinux.pem ubuntu@<IP_PUBLICO_DA_EC2>
```

* **Limpar o conteúdo existente no diretório padrão do Nginx na EC2**:
```
sudo rm -rf /var/www/html/*
```
* Isso remove a página de boas-vindas padrão do Nginx e qualquer outro arquivo existente.

* **Mover o conteúdo do projeto para o diretório de hospedagem do Nginx**:
```
sudo mv /tmp/nome-da-pasta-da-pagina/* /var/www/html/
```

* **Ajustar as permissões dos arquivos para o Nginx**:
```
sudo chown -R www-data:www-data /var/www/html 
sudo chmod -R 755 /var/www/html
```
* Isso garante que o usuário www-data (com o qual o Nginx opera) tenha permissão para ler e servir seus arquivos.

* **Recarregar o Nginx para aplicar as mudanças**:
```
sudo systemctl reload nginx
```

### 2.3. Configuração de Reinício Automático do Nginx com Systemd

Para garantir que o Nginx reinicie automaticamente se o serviço parar por qualquer motivo inesperado: 

* **Conectar-se à instância EC2 via SSH (caso já não esteja conectado)**
  
* **Criar ou editar um arquivo de override para o serviço Nginx do Systemd**:
```
sudo systemctl edit nginx
```
* Este comando abrirá um editor de texto para o arquivo de override.

* **Adicionar o seguinte conteúdo ao arquivo de override**:
```
[Service]
Restart=always
RestartSec=5s
```
  * Restart=always: Configura o Systemd para reiniciar o serviço se ele terminar. 

  * RestartSec=5s: Define um atraso de 5 segundos antes de tentar o reinício. 

  * Após adicionar as linhas, usa-se Ctrl + X, Y para salvar, Enter para confirmar (no editor Nano). 

* **Recarregar o daemon do Systemd**:
```
sudo systemctl daemon-reload
```
  * Isso informa ao Systemd para reler as configurações dos serviços, incluindo o override recém-criado.

* **Reiniciar o serviço Nginx para aplicar a nova configuração**:
```
sudo systemctl restart nginx
```

* **Verificar se a configuração de reinício foi aplicada corretamente**:
```
systemctl show nginx | grep "Restart"
```
  * A saída esperada é Restart=always.

### 2.4. Verificação Final

* **Abrir o navegador web e acessar o endereço IP público da instância EC2. A página deve estar rodando**.

## Etapa 3: Monitoramento e Notificações
Para monitorar a disponibilidade do site e receber alertas em caso de falha, foi criado um script em Bash. O script realiza uma verificação periódica no site, registra o status em um arquivo de log e envia notificações para um canal do Discord via Webhook quando o site estiver fora do ar ou apresentar erro de resposta.

### 3.1. Preparação do Ambiente para o Script de Monitoramento
Com a instância EC2 conectada via SSH:

* **Criar o diretório para os logs**:
```
sudo mkdir -p /var/log/monitoramento
```

* **Criar o arquivo de log site_monitor.log dentro do diretório de monitoramento**:
```
sudo touch /var/log/monitoramento/site_monitor.log
```

* **Atribuir a propriedade do arquivo de log ao usuário ubuntu, permitindo que o script escreva nele**:
```
sudo chown ubuntu:ubuntu /var/log/monitoramento/site_monitor.log
```

### 3.2. Criação do Script de Monitoramento (Bash)

* **Criar o arquivo do script (no diretório home do usuário ubuntu na instância EC2)**:
```
nano ~/site_monitor.sh
```

* **Primeira linha, indica que o script deve ser interpretado com o Bash, padrão para scripts em sistemas Linux**:
```
#!/bin/bash
```

* **Definição de Variáveis**:
```
SITE_URL="http://<IP_PUBLICO_DA_INSTANCIA>/" 
TIMEOUT_SECONDS=10
```
  * SITE_URL: URL que será monitorada.
  * TIMEOUT_SECONDS: tempo máximo que o script espera por uma resposta do site.

```
LOG_DIR="/var/log/monitoramento"
LOG_FILE="${LOG_DIR}/site_monitor.log"
```
  * Diretório e nome do arquivo onde os registros serão salvos.

```
WEBHOOK_DISCORD="https://discordapp.com/api/webhooks/WEBHOOK"
```
  * URL do webhook usado para enviar alertas ao Discord. Esse valor deve ser obtido nas configurações de integração do canal no Discord.

* **Função para envio de notificações**:
```
enviar_alerta() {
    local mensagem="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Enviando alerta: ${mensagem}" >> "${LOG_FILE}"

    if [[ -n "$WEBHOOK_DISCORD" ]]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"${mensagem}\"}" \
             "$WEBHOOK_DISCORD" &>/dev/null
    fi
}
```
  * A função registra a tentativa no log e envia uma mensagem JSON ao Discord.
  * O curl realiza o envio silenciosamente (&>/dev/null) para evitar poluição do terminal.

* **Função de verificação do site**:
```
verificar_site() {
    HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout "$TIMEOUT_SECONDS" "$SITE_URL")
    CURL_EXIT_CODE=$?
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if [ "$CURL_EXIT_CODE" -eq 0 ]; then
        if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "$TIMESTAMP - OK - Site online (HTTP $HTTP_STATUS)" >> "$LOG_FILE"
        else
            echo "$TIMESTAMP - ERRO - Status inesperado: $HTTP_STATUS" >> "$LOG_FILE"
            enviar_alerta "⚠️ Erro no site: status HTTP $HTTP_STATUS"
        fi
    else
        echo "$TIMESTAMP - ERRO - Falha na conexão (código $CURL_EXIT_CODE)" >> "$LOG_FILE"
        enviar_alerta "🚨 Site inacessível! Erro de conexão ou timeout"
    fi
}
```
  * Realiza uma requisição HTTP silenciosa ao site com -s.
  * Avalia o código de status retornado:
    *  200: site no ar.
    *  Qualquer outro código: erro.
    *  Sem resposta: erro de conexão.
  *  Registra o resultado no log e aciona o alerta, se necessário.

* **Execução do script**:
```
verificar_site
```
  * Essa linha chama a função principal e executa todo o monitoramento.
  * Pressionar Ctrl + X, depois Y para salvar, e Enter para confirmar o nome do arquivo.

* **Dar permissão de execução para o script**:
```
chmod +x ~/site_monitor.sh
```




















