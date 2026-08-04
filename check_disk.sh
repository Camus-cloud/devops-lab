#!/bin/bash
USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$USAGE" -gt 80 ]; then
  echo "ALERTE : disque utilisé à ${USAGE}%"
else
  echo "OK : disque utilisé à ${USAGE}%"
fi
