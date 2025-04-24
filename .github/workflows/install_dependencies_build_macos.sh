bison -V
brew unlink bison
brew install bison
echo 'export PATH="/usr/local/opt/bison/bin:$PATH"' >> ~/.bashrc
export PATH=/usr/local/opt/bison/bin:$PATH
export LDFLAGS="-L/usr/local/opt/bison/lib"
source ~/.bashrc
bison -V
