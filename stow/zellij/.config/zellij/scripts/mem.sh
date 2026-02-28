#!/bin/sh
vm_stat | awk '/page size/{for(i=1;i<=NF;i++)if($i+0>999)pg=$i+0}/active:/{a=int($NF)}/wired/{w=int($NF)}END{printf "%5.1fG",(a+w)*pg/1073741824}'
