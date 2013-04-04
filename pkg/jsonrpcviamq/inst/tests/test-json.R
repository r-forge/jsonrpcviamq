# https://github.com/hadley/devtools/wiki/Testing

context("json conversions");
require(RJSONIO);


test_that("can create an rpc error response", {
	result <- jsonRPCviaMQ.toJsonRpcError(id="123", error_code=-234, error_message="error 123 message");
	
	# decode the result, so we can compare the values
	robj <- fromJSON(result);

	# check the component parts because the string will always be formatted slightly differently
	expect_equal(robj[['error']][['code']],-234);
	expect_equal(robj[['error']][['message']],"error 123 message");
	expect_equal(robj[['id']],"123");
})


test_that("can create an rpc success response, body is a number", {
	result <- jsonRPCviaMQ.toJsonRpcSuccess(id="179", result=-17);

	# decode the result, so we can compare the values
	robj <- fromJSON(result);
	
	# check the component parts because the string will always be formatted slightly differently
	expect_equal(robj[['result']],-17);
	expect_equal(robj[['id']],"179");
})


test_that("can create an rpc success response, body is a string", {
	result <- jsonRPCviaMQ.toJsonRpcSuccess(id="488", result="this is a string");

	# decode the result, so we can compare the values
	robj <- fromJSON(result);
	
	# check the component parts because the string will always be formatted slightly differently
	expect_equal(robj[['result']],"this is a string");
	expect_equal(robj[['id']],"488");
})


test_that("can create an rpc success response, body is a list", {
	result <- jsonRPCviaMQ.toJsonRpcSuccess(id="421", result=c("string1","string2","string3"));

	# decode the result, so we can compare the values
	robj <- fromJSON(result);
	
	# check the component parts because the string will always be formatted slightly differently
	expect_equal(robj[['result']][1],"string1");
	expect_equal(robj[['result']][2],"string2");
	expect_equal(robj[['result']][3],"string3");
	expect_equal(robj[['id']],"421");
})
