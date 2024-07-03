default:
  just --list

build:
  CGO_ENABLED=1 go build ../shell-operator/cmd/shell-operator/

debug:
  ./shell-operator start --hooks-dir /home/decoder/dev/shell-operator-blog/hooks --tmp-dir /home/decoder/dev/shell-operator-blog/tmp --log-type color
