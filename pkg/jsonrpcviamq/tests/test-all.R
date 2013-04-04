library(testthat)
library(jsonRPCviaMQ)
library(futile.logger);

# only show flog.debug logging statements
flog.threshold(DEBUG, name='jsonRPCviaMQ');

# execute the tests under inst/tests
# https://github.com/hadley/devtools/wiki/Testing
test_package("jsonRPCviaMQ")