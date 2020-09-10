pushd %~dp0\GDIndex\web
call yarn build
call git add .
call git commit -m "Update"
call git push origin master
popd