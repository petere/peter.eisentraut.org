set terminal svg size 600, 400 dynamic
set output 'pg-compiler-perf.svg'

set style data histogram
set style fill solid
set style histogram clustered gap 2
set xtics scale 0 rotate by -45
set title "PostgreSQL pgbench performance with different compilers"
set yrange [0:80000]
plot 'pg-compiler-perf.dat' using 2:xtic(1) ti col, '' u 3 ti col, '' u 4 ti col, '' u 5 ti col
