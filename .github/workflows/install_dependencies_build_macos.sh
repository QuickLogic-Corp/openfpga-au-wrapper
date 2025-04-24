bison -V
brew unlink bison
echo 'export PATH="/usr/local/opt/bison/bin:$PATH"' >> ~/.bashrc
export PATH=/usr/local/Cellar/bison/3.0.4/bin:$PATH
export LDFLAGS="-L/usr/local/opt/bison/lib"
source ~/.bashrc
bison -V
