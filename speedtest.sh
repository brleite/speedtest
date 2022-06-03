#!/bin/bash

BASEDIR=$(dirname "$0")

TMPFILE=/tmp/speedtest.tmp
HISTORICO=/home/brleite/speedtest_historico.csv
THRESHOLD_DOWNLOAD=37500000
THRESHOLD_UPLOAD=2500000
THRESHOLD_LATENCIA_ORIGINAL=20.000
THRESHOLD_LATENCIA=`echo $THRESHOLD_LATENCIA_ORIGINAL | sed "s/\.//g"`

CONTROLE_DOWNLOAD=/tmp/controle_download.txt
CONTROLE_UPLOAD=/tmp/controle_upload.txt
CONTROLE_LATENCIA=/tmp/controle_latencia.txt

PYTHON_NOTIFY=$BASEDIR/notify.py

speedtest --format=csv > $TMPFILE

HISTORICO_TMP=`cat $TMPFILE`
HISTORICO_TMP="\""`date "+%Y-%m-%d %T"`"\",$HISTORICO_TMP" 
echo "$HISTORICO_TMP" >> $HISTORICO

LATENCIA_ORIGINAL=`cut -d , -f 3 $TMPFILE | sed "s/\"//g"`
LATENCIA=`echo $LATENCIA_ORIGINAL | sed "s/\.//g"`
DOWNLOAD=`cut -d , -f 6 $TMPFILE | sed "s/\"//g"`
UPLOAD=`cut -d , -f 7 $TMPFILE | sed "s/\"//g"`

function enviaNotificacaoPiora {
  ARQUIVO_CONTROLE=$1
  MENSAGEM=$2

  if [ -f "$ARQUIVO_CONTROLE" ]; then
    current_value=`cat $ARQUIVO_CONTROLE`

    if [ $current_value == "0" ]; then
      echo "Enviando notificacao"

      python3 $PYTHON_NOTIFY "$MENSAGEM"

      echo "1" > $ARQUIVO_CONTROLE
    else
      echo "Não é preciso enviar notificação"
    fi
  else
    echo "Enviando notificacao"
    
    python3 $PYTHON_NOTIFY "$MENSAGEM"

    echo "1" > $ARQUIVO_CONTROLE
  fi
}

function enviaNotificacaoMelhora {
  ARQUIVO_CONTROLE=$1
  MENSAGEM=$2

  if [ -f "$ARQUIVO_CONTROLE" ]; then
    current_value=`cat $ARQUIVO_CONTROLE`

    if [ $current_value == "0" ]; then
      echo "Não precisa de notificacao"
    else
      echo "Enviando notificação"

      python3 $PYTHON_NOTIFY "$MENSAGEM"

      echo "0" > $ARQUIVO_CONTROLE
    fi
  else
    echo "Enviando notificacao"

    python3 $PYTHON_NOTIFY "$MENSAGEM"

    echo "0"  > $ARQUIVO_CONTROLE
  fi
}



echo "Latência: $LATENCIA_ORIGINAL (ms)"
echo "Download: $DOWNLOAD (MBps)"
echo "Upload: $UPLOAD (MBps)"

if (( DOWNLOAD < THRESHOLD_DOWNLOAD )); then
  message="Download abaixo do esperado ($THRESHOLD_DOWNLOAD): $DOWNLOAD (MBps)"

  echo $message

  enviaNotificacaoPiora "$CONTROLE_DOWNLOAD" "$message"
else
  message="Download dentro do esperado ($THRESHOLD_DOWNLOAD): $DOWNLOAD (MBps)"

  echo $message

  enviaNotificacaoMelhora "$CONTROLE_DOWNLOAD" "$message"
fi

if (( UPLOAD < THRESHOLD_UPLOAD )); then
  message="Upload abaixo do esperado ($THRESHOLD_UPLOAD): $UPLOAD (MBps)"

  echo $message

  enviaNotificacaoPiora "$CONTROLE_UPLOAD" "$message"
else
  message="Upload dentro do esperado ($THRESHOLD_UPLOAD): $UPLOAD (MBps)"

  echo $message

  enviaNotificacaoMelhora "$CONTROLE_UPLOAD" "$message"
fi

if (( LATENCIA > THRESHOLD_LATENCIA )); then
  message="Latência acima do esperado ($THRESHOLD_LATENCIA_ORIGINAL): $LATENCIA_ORIGINAL (ms)"

  echo $message
  
  enviaNotificacaoPiora "$CONTROLE_LATENCIA" "$message"
else
  message="Latência dentro do esperado ($THRESHOLD_LATENCIA_ORIGINAL): $LATENCIA_ORIGINAL (ms)"

  echo $message

  enviaNotificacaoMelhora "$CONTROLE_LATENCIA" "$message"
fi
