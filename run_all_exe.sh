for i in {1..12}
do
    echo "gcc out_t$i.qv.c -o t$i"
    gcc out_t$i.qv.c -o t$i
    echo "./t$i.exe"
    ./t$i.exe
    echo ""
done