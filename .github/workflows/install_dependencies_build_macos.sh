bison -V
brew unlink bison
brew install bison
echo 'export PATH="/usr/local/opt/bison/bin:$PATH"' >> /Users/runner/.bash_profile
export PATH=/usr/local/opt/bison/bin:$PATH
echo 'export LDFLAGS="-L/usr/local/opt/bison/lib"' >> /Users/runner/.bash_profile
export LDFLAGS="-L/usr/local/opt/bison/lib"
source ~/.bash_profile
bison -V
