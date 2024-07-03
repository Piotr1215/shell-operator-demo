default:
  just --list

debug:
  ./shell-operator start --hooks-dir /home/decoder/dev/shell-operator-blog/hooks --tmp-dir /home/decoder/dev/shell-operator-blog/tmp --log-type color
