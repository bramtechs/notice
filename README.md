# notice
Simple program that list all TODO's and HACKs present in your source code.

## Usage
```shell
./notice --help
```
```
Example: ./notice -i ~/dev/my-project -o ~/dev/my-project/TODO.md -v -e c,cpp
-i        --src 
-o     --output 
-b       --bare 
-v    --verbose 
-e --extensions 
-h       --help This help information.
```

### Things to know
> Leave output empty to print to stdout.

> Seperate multiple extensions with comma.

> Hidden files and folders get ignored.