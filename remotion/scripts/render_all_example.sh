cd /home/claude/shorts
for r in "0 469" "470 939" "940 1409" "1410 1879"; do set -- $r;
  [ -f out/azfinal/part_$1.mp4 ] || CRF=16 node scripts/render-range.mjs Alcatraz out/azfinal/part_$1.tmp.mp4 $1 $2 1 > out/azfinal/log_$1.txt 2>&1 && mv out/azfinal/part_$1.tmp.mp4 out/azfinal/part_$1.mp4
done
echo ALLDONE > out/azfinal/done.txt
