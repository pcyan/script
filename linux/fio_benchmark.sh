#!/bin/bash


##################################################
# title: fio_benchmark.sh
# description: for nas disk speed test
# how to use: 
#    ./fio_benchmark.sh
#
##################################################

set -e # 启用错误退出模式

# 配置
FIO_LOGFILE="fio.log"    # fio 日志文件
HTML_REPORT="fio_report.html"  # HTML 报告文件

## 生成一个随机文件名，避免被缓存
function random_filename(){
    timestamp=$(date +"%Y%m%d%H%M%S%N")
    test_file_name="test_rand_$timestamp"
    echo "$test_file_name"
}

function run_disk_test(){
    # 清空日志文件
    > "$FIO_LOGFILE"

    ## 测试顺序读写性能，线程少，文件大
    echo "Running fio job 4k顺序混合读写"
    test_file_name=$(random_filename)
    fio --name="job_4k顺序混合读写" --filename=$test_file_name --size=1024M --bs=4k --ioengine=libaio --iodepth=4 \
        --readwrite=rw --rwmixread=70 --runtime=60 --time_based --output-format=json \
        >> "$FIO_LOGFILE"
    rm $test_file_name
    echo "Job job 4k顺序混合读写 completed."

    echo "Running fio job 32k顺序混合读写"
    test_file_name=$(random_filename)
    fio --name="job_32k顺序混合读写" --filename=$test_file_name --size=1024M --bs=32k --ioengine=libaio --iodepth=4 \
        --readwrite=rw --rwmixread=70 --runtime=60 --time_based --output-format=json \
        >> "$FIO_LOGFILE"
    rm $test_file_name
    echo "Job job 32k顺序混合读写 completed."

    echo "Running fio job 1024k顺序混合读写"
    test_file_name=$(random_filename)
    fio --name="job_1024k顺序混合读写" --filename=$test_file_name --size=1024M --bs=1024k --ioengine=libaio --iodepth=4 \
        --readwrite=rw --rwmixread=70 --runtime=60 --time_based --output-format=json \
        >> "$FIO_LOGFILE"
    rm $test_file_name
    echo "Job job 1024k顺序混合读写 completed."

    ## 测试顺序读写性能，线程多，文件小
    echo "Running fio job 4k随机混合读写"
    test_file_name=$(random_filename)
    fio --name="job_4k随机混合读写" --filename=$test_file_name --size=100M --bs=4k --ioengine=libaio --iodepth=32 \
        --readwrite=randrw --rwmixread=70 --runtime=60 --time_based --output-format=json \
        >> "$FIO_LOGFILE"
    rm $test_file_name
    echo "Job job 4k随机混合读写 completed."

    echo "Running fio job 32k随机混合读写"
    test_file_name=$(random_filename)
    fio --name="job_32k随机混合读写" --filename=$test_file_name --size=100M --bs=32k --ioengine=libaio --iodepth=32 \
        --readwrite=randrw --rwmixread=70 --runtime=60 --time_based --output-format=json \
        >> "$FIO_LOGFILE"
    rm $test_file_name
    echo "Job job 32k随机混合读写 completed."

    echo "Running fio job 1024k随机混合读写"
    test_file_name=$(random_filename)
    fio --name="job_1024k随机混合读写" --filename=$test_file_name --size=100M --bs=1024k --ioengine=libaio --iodepth=32 \
        --readwrite=randrw --rwmixread=70 --runtime=60 --time_based --output-format=json \
        >> "$FIO_LOGFILE"
    rm $test_file_name
    echo "Job job 1024k随机混合读写 completed."

}

function generate_html_report(){
    # 解析 fio 日志并生成 HTML 报告
    echo "Generating HTML report..."

    # HTML 报告头部
    cat <<EOF > "$HTML_REPORT"
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>FIO Benchmark Report</title>
        <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            h1 { color: #333; }
            .chart { margin-bottom: 40px; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <h1>FIO Benchmark Report</h1>
        <table>
            <tr>
                <th>Job</th>
                <th>Read Avg (MB/s)</th>
                <th>Read Max (MB/s)</th>
                <th>Read Min (MB/s)</th>
                <th>Write Avg (MB/s)</th>
                <th>Write Max (MB/s)</th>
                <th>Write Min (MB/s)</th>
            </tr>
EOF

    # 使用 jq 解析 fio 日志
    job_count=0
    while read -r json; do
        job_count=$((job_count + 1))
        jobname=$(echo "$json" | jq '.jobs[0].jobname')
        read_avg=$(echo "$json" | jq '.jobs[0].read.bw_mean / 1024')  # 转换为 MB/s
        read_max=$(echo "$json" | jq '.jobs[0].read.bw_max / 1024')   # 转换为 MB/s
        read_min=$(echo "$json" | jq '.jobs[0].read.bw_min / 1024')   # 转换为 MB/s
        write_avg=$(echo "$json" | jq '.jobs[0].write.bw_mean / 1024')  # 转换为 MB/s
        write_max=$(echo "$json" | jq '.jobs[0].write.bw_max / 1024')   # 转换为 MB/s
        write_min=$(echo "$json" | jq '.jobs[0].write.bw_min / 1024')   # 转换为 MB/s

        # 将结果写入 HTML 表格
        cat <<EOF >> "$HTML_REPORT"
            <tr>
                <td>$jobname</td>
                <td>$read_avg</td>
                <td>$read_max</td>
                <td>$read_min</td>
                <td>$write_avg</td>
                <td>$write_max</td>
                <td>$write_min</td>
            </tr>
EOF
    done < <(jq -c '.' "$FIO_LOGFILE")

    # HTML 报告中部（图表部分）
    cat <<EOF >> "$HTML_REPORT"
        </table>
        <div id="readChart" class="chart"></div>
        <div id="writeChart" class="chart"></div>
        <script>
            // 读取速度数据
            const readData = {
                x: [],
                y: [],
                type: 'bar',
                name: 'Read Speed (MB/s)',
                marker: { color: 'blue' }
            };

            // 写入速度数据
            const writeData = {
                x: [],
                y: [],
                type: 'bar',
                name: 'Write Speed (MB/s)',
                marker: { color: 'green' }
            };

EOF

    # 提取读写速度数据并写入 HTML
    job_count=0
    while read -r json; do
        job_count=$((job_count + 1))
        jobname=$(echo "$json" | jq '.jobs[0].jobname')
        read_avg=$(echo "$json" | jq '.jobs[0].read.bw_mean / 1024')
        write_avg=$(echo "$json" | jq '.jobs[0].write.bw_mean / 1024')

        echo "        readData.x.push('$jobname');" >> "$HTML_REPORT"
        echo "        readData.y.push($read_avg);" >> "$HTML_REPORT"
        echo "        writeData.x.push('$jobname');" >> "$HTML_REPORT"
        echo "        writeData.y.push($write_avg);" >> "$HTML_REPORT"
    done < <(jq -c '.' "$FIO_LOGFILE")

    # HTML 报告尾部
    cat <<EOF >> "$HTML_REPORT"
            // 绘制读取速度图表
            Plotly.newPlot('readChart', [readData], {
                title: 'Read Speed (MB/s)',
                xaxis: { title: 'Job' },
                yaxis: { title: 'Speed (MB/s)' }
            });

            // 绘制写入速度图表
            Plotly.newPlot('writeChart', [writeData], {
                title: 'Write Speed (MB/s)',
                xaxis: { title: 'Job' },
                yaxis: { title: 'Speed (MB/s)' }
            });
        </script>
    </body>
    </html>
EOF

    echo "HTML report generated: $HTML_REPORT"
}

run_disk_test
generate_html_report