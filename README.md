# nginx Log Analyser Tools
A tool to analyze nginx logs from the command line. This project is part of [roadmap.sh](https://roadmap.sh/projects/log-archive-tool) DevOps projects.

## Features
- Validates if log file path was provided as an argument
- Validates if log file path matches the valid regex
- Validates if log file exists
- Displays Top 5 IP addresses with the most requests
- Displays Top 5 most requested paths
- Displays Top 5 response status codes
- Displays Top 5 user agents
- Validates if the response statuses are correct HTTP status codes (numerical and 3 digits)

The log file is a nginx sample log from [here](https://gist.githubusercontent.com/kamranahmedse/e66c3b9ea89a1a030d3b739eeeef22d0/raw/77fb3ac837a73c4f0206e78a236d885590b7ae35/nginx-access.log).

## Getting Started

### Instructions

1. Clone repo:
```bash
git clone https://github.com/islandskan/https://github.com/islandskan/Nginx-Log-Analyser
cd nginx-log-analyser
```

2. Make the script executable
```bash
chmod +x log-analyser.sh
```

3. Execute script
```bash
log-analyser.sh nginx-sample-log.log
```

#### Usage
Usage: `$SCRIPT_NAME <log-file>`

Arguments:
`<log-file>`        The name/path of the log file to analyze. For this specific use case, we use `nginx-sample-log.log`. Valid log file pattern: A-Z, a-z, 0-9, /, ., _, -, and either `.txt` or `.log`

### Expected Output
```bash
Top 5 IP addresses with the most requests:
45.76.135.253 - 1000 requests
142.93.143.8 - 600 requests
178.128.94.113 - 50 requests
43.224.43.187 - 30 requests
178.128.94.113 - 20 requests

Top 5 most requested paths:
/api/v1/users - 1000 requests
/api/v1/products - 600 requests
/api/v1/orders - 50 requests
/api/v1/payments - 30 requests
/api/v1/reviews - 20 requests

Top 5 response status codes:
200 - 1000 requests
404 - 600 requests
500 - 50 requests
401 - 30 requests
304 - 20 requests
```
## Learning Notes

### Regex pattern for log file
`^`                 Start of string
`[a-zA-Z0-9._/-]+`  One or more letter, number, dot, underscore, dash or slash  
`\.`                (Escaped) dot before file suffix
`(log|txt)`         Either log or txt
`$`                 End of string
 
### Use of "NR <= 5" instead of "head -5"
- I noticed that my use of the `set -e` flag interacted with `head -5` in the `awk` blocks in a way I didn't expect.
- with `head -5`, the pipeline immediately closes the input pipe after reading the first 5 lines.
- if `awk` is still trying to read/write more lines to the same pipe, it receives `SIGPIPE` signal.
- the `set -e` flag sees that awk failed and exits on error
- I solved it by using `NR` inside the `awk` block to get the top 5 line numbers.

### The `awk` regex in `get_response_status_codes`
- Some of the 9th columns aren't status codes but instead "-"
- I wanted to filter them out and just display the responses with numerical, 3 digit codes.
- I used the following `awk` regex to achieve this:
`awk '$9 ~ /^[0-9]{3}$/' {print $9} $LOG_FILE`
- `$9 ~`            check if 9tn column matches the pattern to the right
- `/ ... /`         pattern delimiters
- `^`               start of field
- `[0-9]{3}`        exactly three digits
- `$`               end of field

### Use of `awk -F '\"` `'{print $6}'` in `get_user_agents`
- Looking at a log message from the sample logs
`"DigitalOcean Uptime Probe 0.22.0 (https://digitalocean.com)"` is the user agent
- However, the default delimiter in `awk` is spaces, even if the user agent technically is a single string. 
- I would've had to use `$12`, `$13`, `$14`, `$15`, and `$16` to access all of the columns needed for the user agent.
- By using `awk -F '\"'`, this changes the delimiter to ""
- `awk` treats everything before and in between "" as single sections. 

### Further formatting the user agent string in `get_user_agents`
- After the user agent string has left the first `awk` (see above), `awk` goes back to its default behaviour again
- Meaning, it treats strings as space separated columns once again.
- I solved this by:
1. Extracting the requests from `$1` into an `awk` variable
2. "Remove" the original `$1` at the start of the string (more like making it empty)
3. Remove empty spaces or tabs at start of string with `sub(/^[ \t]+/, "")`
truncate and print the rest of the string, and finally print the extracted requests
4. Print and format the line using `printf "%-75.70s %s requests\n", $0, count`. `-75.70` reserves 75 character left aligned space and truncates the user agent string if it's longer than 70 characters 
