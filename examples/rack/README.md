## Example Rack app to compare with `prometheus_client`

### Setup
```bash
bundle install

bin/iodine config.ru # to run with rb_rs gem
bin/iodine config_prom_client.ru # to run with prometheus_client gem
bin/iodine config_blank.ru # to run without middlewares

# Default endpoint to test Collector middleware
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000

# metrics endpoint to test Exporter middleware
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000/metrics
```


### Results

Running with `Iodine.threads = 1` and `Iodine.workers = 1` on my M1 Max laptop

#### Without middlewares
```bash
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000
Running 10s test @ http://localhost:3000
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   133.96us  279.95us   9.25ms   98.00%
    Req/Sec    43.64k     6.44k   52.56k    80.20%
  Latency Distribution
     50%  103.00us
     75%  130.00us
     90%  155.00us
     99%    0.89ms
  876933 requests in 10.10s, 112.90MB read
Requests/sec:  86815.23
Transfer/sec:     11.18MB
```

#### With prometheus_client
##### Collector
```bash
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000
Running 10s test @ http://localhost:3000
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   177.09us  111.68us   6.38ms   96.49%
    Req/Sec    28.60k     1.85k   31.97k    73.76%
  Latency Distribution
     50%  165.00us
     75%  188.00us
     90%  215.00us
     99%  418.00us
  574807 requests in 10.10s, 74.00MB read
Requests/sec:  56907.07
Transfer/sec:      7.33MB
```

##### Exporter
```bash
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000/metrics
Running 10s test @ http://localhost:3000/metrics
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   661.38us  155.06us   6.20ms   93.54%
    Req/Sec     7.62k   404.03     8.02k    84.65%
  Latency Distribution
     50%  629.00us
     75%  708.00us
     90%  793.00us
     99%    1.06ms
  153246 requests in 10.10s, 268.91MB read
Requests/sec:  15171.11
Transfer/sec:     26.62MB
```

#### With prometheus_rb_rs
##### Collector
```bash
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000
Running 10s test @ http://localhost:3000
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   152.27us  119.68us   7.31ms   97.09%
    Req/Sec    33.10k     2.47k   37.23k    74.75%
  Latency Distribution
     50%  144.00us
     75%  165.00us
     90%  188.00us
     99%  389.00us
  665180 requests in 10.10s, 85.64MB read
Requests/sec:  65858.04
Transfer/sec:      8.48MB
```

##### Exporter
```bash
wrk -c 10 -t 2 -d 10 --latency http://localhost:3000/metrics
Running 10s test @ http://localhost:3000/metrics
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   172.54us  216.75us   8.99ms   98.54%
    Req/Sec    30.35k     2.00k   33.67k    76.24%
  Latency Distribution
     50%  157.00us
     75%  178.00us
     90%  198.00us
     99%  457.00us
  609962 requests in 10.10s, 0.94GB read
Requests/sec:  60395.16
Transfer/sec:     95.27MB
```

