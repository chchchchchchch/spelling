#!/bin/bash

  SVG=131126_Spellism.svg

  TMPDIR=. ; OUTDIR=../FREEZE
  MASTERNAME=`basename $SVG | cut -d "." -f 1`

# --------------------------------------------------------------------------- #
# SEPARATE SVG BODY FOR EASIER PARSING (BUG FOR EMPTY LAYERS SOLVED)
# --------------------------------------------------------------------------- #

      sed 's/ / \n/g' $SVG | \
      sed '/^.$/d' | \
      sed -n '/<\/metadata>/,/<\/svg>/p' | sed '1d;$d' | \
      sed ':a;N;$!ba;s/\n/ /g' | \
      sed 's/<\/g>/\n<\/g>/g' | \
      sed 's/\/>/\n\/>\n/g' | \
      sed 's/\(<g.*inkscape:groupmode="layer"[^"]*"\)/QWERTZUIOP\1/g' | \
      sed ':a;N;$!ba;s/\n/ /g' | \
      sed 's/QWERTZUIOP/\n\n\n\n/g' | \
      sed 's/display:none/display:inline/g' >> ${SVG%%.*}.tmp

  SVGHEADER=`tac $SVG | sed -n '/<\/metadata>/,$p' | tac`

# --------------------------------------------------------------------------- #
# WRITE LIST WITH LAYERS
# --------------------------------------------------------------------------- #

  LAYERLIST=layer.list ; if [ -f $LAYERLIST ]; then rm $LAYERLIST ; fi
  TYPESLIST=types.list ; if [ -f $TYPESLIST ]; then rm $TYPESLIST ; fi

  CNT=1
  for LAYER in `cat ${SVG%%.*}.tmp | \
                sed 's/ /ASDFGHJKL/g' | \
                sed '/^.$/d' | \
                grep -v "label=\"XX_"`
   do
       NAME=`echo $LAYER | \
             sed 's/ASDFGHJKL/ /g' | \
             sed 's/\" /\"\n/g' | \
             grep inkscape:label | grep -v XX | \
             cut -d "\"" -f 2 | sed 's/[[:space:]]\+//g'`
       echo $NAME >> $LAYERLIST
       CNT=`expr $CNT + 1`
  done

  cat $LAYERLIST | sed '/^$/d' | sort | uniq > $TYPESLIST

# --------------------------------------------------------------------------- #
# GENERATE CODE FOR FOR-LOOP TO EVALUATE COMBINATIONS
#---------------------------------------------------------------------------- #

  KOMBILIST=kombinationen.list ; if [ -f $KOMBILIST ]; then rm $KOMBILIST ; fi

  # RESET (IMPORTANT FOR 'FOR'-LOOP)
  LOOPSTART=""
  VARIABLES=""
  LOOPCLOSE=""  

  CNT=0  
  for BASETYPE in `cat $TYPESLIST | cut -d "-" -f 1 | sort | uniq`
   do
      LOOPSTART=${LOOPSTART}"for V$CNT in \`grep $BASETYPE $TYPESLIST \`; do "
      VARIABLES=${VARIABLES}'$'V${CNT}" "
      LOOPCLOSE=${LOOPCLOSE}"done; "

      CNT=`expr $CNT + 1`
  done

# --------------------------------------------------------------------------- #
# EXECUTE CODE FOR FOR-LOOP TO EVALUATE COMBINATIONS
# --------------------------------------------------------------------------- #

 #echo ${LOOPSTART}" echo $VARIABLES >> $KOMBILIST ;"${LOOPCLOSE}
  eval ${LOOPSTART}" echo $VARIABLES >> $KOMBILIST ;"${LOOPCLOSE}

# ------------------------------------------------------------------------------- #
# WRITE SVG FILES ACCORDING TO POSSIBLE COMBINATIONS
# ------------------------------------------------------------------------------- #

  for KOMBI in `cat $KOMBILIST | sed 's/ /DHSZEJDS/g'`
   do
      KOMBI=`echo $KOMBI | sed 's/DHSZEJDS/ /g'`
      NAME=$MASTERNAME
      OUT=$TMPDIR/TMP${NAME}_`echo ${KOMBI} | \
                                 md5sum | cut -c 1-7`

      echo "$SVGHEADER"                                   >  ${OUT}.svg

       for LAYERNAME in `echo $KOMBI`
        do
          grep -n "label=\"$LAYERNAME\"" ${SVG%%.*}.tmp   >> ${OUT}.tmp
       done

      cat ${OUT}.tmp | sort -n | cut -d ":" -f 2-         >> ${OUT}.svg
      echo "</svg>"                                       >> ${OUT}.svg
      inkscape --export-pdf=${OUT}.pdf \
               ${OUT}.svg

      rm ${OUT}.tmp
  done

# ------------------------------------------------------------------------------- #
# COMBINE PDF FILES
# ------------------------------------------------------------------------------- #
  pdftk $TMPDIR/TMP*.pdf cat output $OUTDIR/${MASTERNAME}.pdf

# --------------------------------------------------------------------------- #
# REMOVE TEMP FILES
# --------------------------------------------------------------------------- #
  rm ${SVG%%.*}.tmp $KOMBILIST $LAYERLIST $TYPESLIST $TMPDIR/TMP*



exit 0;











# for SVG in `ls $TMPDIR/*.svg | head -5`
#  do
#
## COLORS ------------------------------------------------------------------- #
#
#  WHITE="rgb(100%,100%,100%)"
#  BLACK="rgb(0%,0%,0%)"
#  RED="rgb(100%,0%,0%)"
#  GREEN="rgb(0%,100%,0%)"
#
#
## PDF2SVG 0.2.1-2+b3 PROBLEMS (= IMPRECISE) !!
## -> DOWNGRADE: https://github.com/wagle/pdf2svg
## -------------------------------------------------------------------------- #
## MAKE SURE EVERY PATH IS A SINGLE LINE
## -------------------------------------------------------------------------- #
#  inkscape --export-pdf=${SVG%%.*}.pdf \
#           --export-text-to-path \
#           $SVG
#  pdf2svg ${SVG%%.*}.pdf ${SVG%%.*}_PLAIN.svg
## -------------------------------------------------------------------------- #
#
#
## -------------------------------------------------------------------------- #
## MAKE COLOR FILTER
## -------------------------------------------------------------------------- #
#
#  COLORSSTANDARD=`echo "stroke:none|${BLACK}|${RED}|${WHITE}" | \
#                  sed 's/(/\\\(/g' | sed 's/)/\\\)/g'`
#
## COLORSPLUS="QXSW|"`cat ${SVG%%.*}_PLAIN.svg  | \
##                    sed 's/stroke:/\nstroke:/g' | \
##                    sed 's/;/;\n/g' | \
##                    grep stroke: | \
##                    egrep -v "$COLORSSTANDARD" | \
##                    sort | uniq | \
##                    sed ':a;N;$!ba;s/\n//g' | \
##                    sed 's/stroke://g' | \
##                    sed 's/(/\\\(/g' | sed 's/)/\\\)/g' | \
##                    sed 's/;/|/g'`"XXXXXXX"
#
## -------------------------------------------------------------------------- #
## MAKE SEPARATE SVGS FOR ADDITIONAL COLORS (= NOT BLACK,WHITE,RED,GREEN)
## -------------------------------------------------------------------------- #
#
## for COLOR in `echo $COLORSPLUS | sed 's/|/ /g' | \
##               sed 's/ XXXXXXX//g' | sed 's/QXSW//g'`
##  do
##     # ------------------------------------------- #
##     # RGB TO HEX HACK
##     # ------------------------------------------- #
##     RGB=`echo $COLOR | sed 's/\\\//g'`; echo $RGB
##     convert -size 2x2 xc:"$RGB" rgb.gif
##     convert rgb.gif rgb.xpm
##     HEX=`cat rgb.xpm | grep " #" | \
##          head -1 | cut -d "#" -f 2 | \
##          cut -c 1-6`
##     rm rgb.gif rgb.xpm
##     # ------------------------------------------- #
#
##     COLORCODE=$HEX ; # echo $COLORCODE
##     SVGCOLOR=${SVG%%.*}_LINES_C-${COLORCODE}.svg
#
##     COLORGREP=`echo $COLOR | sed 's/\\\//g'`
#
##     head -2 ${SVG%%.*}_PLAIN.svg                              >  $SVGCOLOR
##     grep stroke:$COLORGREP ${SVG%%.*}_PLAIN.svg               >> $SVGCOLOR
##     echo "</svg>"                                             >> $SVGCOLOR
#
## done
#
## -------------------------------------------------------------------------- #
#
#
#
#
#
#
#
## -------------------------------------------------------------------------- #
## MAKE ONE SVGS FOR STANDARD COLORS (= BLACK,RED,NO WHITE)
## -------------------------------------------------------------------------- #
#
#  COLORSSTANDARD=`echo "${BLACK}|${RED}" | \
#                  sed 's/(/\\\(/g' | sed 's/)/\\\)/g'`
#
#  SVGCOLOR=${SVG%%.*}_LINES_C-000000.svg
#
#  head -2 ${SVG%%.*}_PLAIN.svg                                  >  $SVGCOLOR
#  COLORGREP=`echo $COLORSSTANDARD | \
#             sed 's/(/\\(/g' | sed 's/)/\\)/g' | \
#             sed 's/rgb/stroke:rgb/g'`
#
#  egrep $COLORGREP ${SVG%%.*}_PLAIN.svg                         >> $SVGCOLOR
#  echo "</svg>"                                                 >> $SVGCOLOR
#
## -------------------------------------------------------------------------- #
## CONFORM SVG FOR IMPORT INTO PROCESSING
## -------------------------------------------------------------------------- #
#
## A3 LANDSCAPE (FOR PLOTTER) ----------------------------------------------- #
#  TEMPLATE=i/utils/A3_QUER.svg
#
#  X=1488.189
#  Y=0
#  SCALE=1.25 # POINTS/PIXEL RATIO
#  ROTATE=90
#
#  TRANSFORM="\"translate($X,$Y) scale($SCALE) rotate($ROTATE)\""
#
#  SVGHEADER=`tac $TEMPLATE | sed -n '/<\/metadata>/,$p' | tac`
#
#  for COLORSVG in `ls ${SVG%%.*}_LINES_C-* | sort`
#   do
#        SRCSVG=${COLORSVG}
#        SVG4HPGL=${COLORSVG%%.*}_4HPGL.svg
#
#        echo $SRCSVG
#
#        echo $SVGHEADER           >   ${SVG4HPGL}
#        echo "<g transform=$TRANSFORM>" \
#                                  >>  ${SVG4HPGL}
#        grep "<path" ${SRCSVG} \
#                                  >>  ${SVG4HPGL}
#        echo "</g>"               >>  ${SVG4HPGL}
#        echo "</svg>"             >>  ${SVG4HPGL}
#
#        inkscape --export-pdf=${SVG4HPGL%%.*}.pdf $SVG4HPGL
#        pdf2ps ${SVG4HPGL%%.*}.pdf ${SVG4HPGL%%.*}.ps
#        ps2pdf ${SVG4HPGL%%.*}.ps ${SVG4HPGL%%.*}.pdf
#        pdf2svg ${SVG4HPGL%%.*}.pdf ${SVG4HPGL%%.*}_CONFORM.svg
#
#        rm ${SVG4HPGL%%.*}.ps ${SVG4HPGL%%.*}.pdf
#  done
#
#
## -------------------------------------------------------------------------- #
## WRITE HPGL FILE
## -------------------------------------------------------------------------- #
#
#   PENSAVAILABLE=1
#   HPGL=${SVG%%.*}.hpgl
#
#   echo "IN;"                                       >  $HPGL
#
#   # http://www.isoplotec.co.jp/HPGL/eHPGL.htm
#   # IP p1x,p1y,p2x,p2y;
#   echo "IP0,0,16158,11040;"                        >> $HPGL
#   # http://www.isoplotec.co.jp/HPGL/eHPGL.htm
#   # SC xmin,xmax,ymin,ymax;
#   echo "SC1488,0,0,1052;"                          >> $HPGL
#   echo "VS5;"                                      >> $HPGL
#   echo                                             >> $HPGL
#
#
#   PEN=1
# # -------------------------------------------------------------------------- #
#
#   for SVGCONFORM in `grep -H path $TMPDIR/*_CONFORM.svg | \
#                      cut -d ":" -f 1 | sort | uniq`
#    do
#
#       echo ""                                      >> $HPGL
#       echo "SP${PEN};"                             >> $HPGL
#
#       # DEBUG
#       # cp $SVGCONFORM SP${PEN}-`basename $SVGCONFORM`
#
#       echo $SVGCONFORM > svg.i
#
#       SKETCHNAME=hpgllines_A3_04
#
#       APPDIR=$(dirname "$0")
#       LIBDIR=$APPDIR/src/$SKETCHNAME/application.linux/lib
#       SKETCH=$LIBDIR/$SKETCHNAME.jar
#
#       CORE=$LIBDIR/core.jar
#       GMRTV=$LIBDIR/geomerative.jar
#       BTK=$LIBDIR/batikfont.jar
#
#       LIBS=$SKETCH:$CORE:$GMRTV:$BTK
#
#       java  -Djava.library.path="$APPDIR" \
#             -cp "$LIBS" \
#             $SKETCHNAME
#
#       rm svg.i
#
# # -------------------------------------------------------------------------- #
#    # KEEP ORDER
#       cat hpgl.hpgl                           >> $HPGL
#
#    # RANDOMIZE LINES (PREVENT FLOATING COLOR) 
#      #cat hpgl.hpgl | \
#      #sed 's/PU;/PU;\n/g' | \
#      #sed '/./{H;d;};x;s/\n/={NL}=/g' | \
#      #shuf | sed '1s/={NL}=//;s/={NL}=/\n/g'  >> $HPGL
# # -------------------------------------------------------------------------- #
#
#      PEN=`expr $PEN + 1`
#       if [ $PEN -gt $PENSAVAILABLE ]; then
#            PEN=2
#       fi
#   done
#
# # -------------------------------------------------------------------------- #
#
#   echo "SP0;"   >> $HPGL
# # -------------------------------------------------------------------------- #
#
#   # DEBUG  
#   # cp $SVG4HPGLLINES `basename $SVG4HPGLLINES` 
#   rm hpgl.hpgl ${SVG%%.*}_* ${SVG%%.*}.pdf # $TMPDIR/*_CONFORM.svg
#
#done
#
#
#exit 0;




