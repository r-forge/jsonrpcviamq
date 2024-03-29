# https://github.com/hadley/devtools/wiki/Testing

library(futile.logger);
library(RJSONIO);
context("executeRPC");

	
test_that("can respond to an invalid method name", {
	require(RJSONIO);
	require(futile.logger);
	request <- '{"jsonrpc": "2.0", "method": "xxxyyyzzz", "params": null, "id": "144"}';
	
	response = jsonRPCviaMQ.executeJsonRPC(request);
	robj <- RJSONIO::fromJSON(response);
	
	
	# Method not found response
	# {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}
	expect_equal(robj[['error']][['code']], -32601, info=response);
	expect_equal(robj[['id']], "144");
	
	# make sure the beginning of the error message is expected
	error_message_prefix <- "Method not found";
	expect_equal(substr(robj[['error']][['message']],1,nchar(error_message_prefix)),error_message_prefix);
})



test_that("can respond to an invalid request, missing method", {
	require(RJSONIO);
	require(futile.logger);
	request <- '{"jsonrpc": "2.0", "params": null, "id": "145"}';
	
	response = jsonRPCviaMQ.executeJsonRPC(request);
	robj <- RJSONIO::fromJSON(response);
	
	
	# Method not found response
	expect_equal(robj[['error']][['code']], -32600);
	expect_equal(robj[['id']], "145");
	
	# make sure the beginning of the error message is expected
	error_message_prefix <- "Invalid request";
	expect_equal(substr(robj[['error']][['message']],1,nchar(error_message_prefix)),error_message_prefix);
})


test_that("can respond to an invalid request, missing whole request", {
	require(RJSONIO);
	require(futile.logger);
	request <- '{}';
	
	response = jsonRPCviaMQ.executeJsonRPC(request);
	robj <- RJSONIO::fromJSON(response);
	
	
	# Method not found response
	expect_equal(robj[['error']][['code']], -32600, info=response);
	expect_equal(robj[['id']], NULL);
	
	# make sure the beginning of the error message is expected
	error_message_prefix <- "Invalid request";
	expect_equal(substr(robj[['error']][['message']],1,nchar(error_message_prefix)),error_message_prefix);
})



test_that("can respond to a valid request, Sys.time()", {
	require(RJSONIO);
	require(futile.logger);
	#request <- '{"jsonrpc": "2.0", "method": "Sys.time", "params": [], "id": "349"}';
	request <- '{"jsonrpc": "2.0", "method": "Sys.time", "params": null, "id": "349"}';
	
	# for comparison
	time_before_request <- as.double(Sys.time());
	
	response = jsonRPCviaMQ.executeJsonRPC(request);
	robj <- RJSONIO::fromJSON(response);
	
	# result
	expect_equal(robj[['id']], '349', info=response);
	expect_true(is.double(robj[['result']]));
	expect_true(robj[['result']] >= time_before_request, info=paste("time start: ",time_before_request,", result: ",robj[['result']], sep=""));
})
