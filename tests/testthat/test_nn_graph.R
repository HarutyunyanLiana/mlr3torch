test_that("Linear GraphNetwork works", {
  batch_size = 16L
  d_token = 3L
  task = tsk("iris")
  batch = get_batch(task, batch_size = batch_size, device = "cpu")
  graph = top("input") %>>%
    top("tab_tokenizer", d_token = d_token) %>>%
    top("flatten") %>>%
    top("linear_1", out_features = 10L) %>>%
    top("relu_1") %>>%
    top("linear_2", out_features = 1L)
  network = graph$train(task)[[1L]][[2L]]
  expect_function(network)
  expect_true(inherits(network, "nn_graph"))
})

test_that("GraphNetwork with forking of depth 1 works", {
  d_token = 4L
  batch_size = 9L
  task = tsk("iris")
  batch = get_batch(task, batch_size, device = "cpu")
  graph = top("input") %>>%
    top("tab_tokenizer", d_token = d_token) %>>%
    top("flatten") %>>%
    gunion(
      graphs = list(
        a = top("linear", out_features = 3L) %>>% top("relu"),
        b = top("linear", out_features = 3L)
      )
    ) %>>%
    top("merge", .method = "add", innum = 2L) %>>%
    top("linear", out_features = 1L)
  network = graph$train(task)[[1L]][[2L]]
  expect_function(network)
  expect_true(inherits(network, "nn_graph"))
})

test_that("GraphNetwork with forking (depth 2) works", {
  #
  #                                  --> aa.linear -->
  #                      --> a.linear
  # tokenizer --> flatten            --> ab.linear --> merge
  #
  #                      --> b.linear --------------->
  d_token = 4L
  batch_size = 9L
  task = tsk("iris")
  batch = get_batch(task, batch_size, device = "cpu")
  a = gunion(
    graphs = list(
      c = top("linear", out_features = 3L),
      d = top("linear", out_features = 3L)
    )
  ) %>>%
    top("merge", .method = "mul", innum = 2L)


  graph = top("input") %>>%
    top("select", items = "num") %>>%
    gunion(
      graphs = list(
        a = a,
        b = top("linear", out_features = 3L)
      )
    ) %>>%
    top("merge", .method = "add") %>>%
    top("linear", out_features = 1L)
  network = graph$train(task)[[1L]][[2L]]
  expect_function(network)
  expect_true(inherits(network, "nn_graph"))
})

test_that("fork at the beginning works", {
  graph = top("input") %>>%
    top("select", items = "num") %>>%
    gunion(list(top("linear_1", out_features = 10), top("linear_2", out_features = 10))) %>>%
    top("add")

  task = tsk("iris")
  res = graph$train(task)[[1L]]
  net = res$network
  net(list(num = torch_randn(16, 4)))
})

test_that("GraphNetwork works when a unnamed list is returned by nn_module", {
  # max_pool2d returns a unnamed list whose names we have to set
  task = toytask()
  g = top("input") %>>%
    top("conv2d", kernel_size = 3L, out_channels = 1L) %>>%
    top("max_pool2d", kernel_size = 1L, return_indices = TRUE)

  expect_error(g$train(task), regexp = NA)

})

test_that("Name conflicts", {
  net = nn_graph()
  expect_error(net$add_module("add_module", nn_linear(10, 1)), regexp = NA)

})


# TODO: Need to wait for the pipelines PR
# test_that("would work with multi-output torchops", {
#   TorchOpMO = R6Class("TorchOpMO",
#     inherit = TorchOp,
#     public = list(
#       initialize = function(id = "mo", param_vals = list()) {
#         output = data.table(
#           name = c("output1", "output2"),
#           train = c("ModelConfig", "ModelConfig"),
#           predict = c("Task", "Task")
#         )
#         super$initialize(
#           param_set = ps(),
#           param_vals = param_vals,
#           id = id,
#           output = output
#         )
#       }
#     ),
#     private = list(
#       .build = function(inputs, task) {
#         nn_module("multioutput",
#           forward = function(input) {
#             list(output2 = input - 100, output1 = input + 100)
#           }
#         )()
#       }
#     )
#   )
#
#   op = TorchOpMO$new()
#
#   graph = top("input") %>>%
#     top("select", items = "num") %>>%
#     op
#
#   graph$add_pipeop(top("cat", innum = 2L, dim = 2L))
#   graph2 = graph$clone(deep = TRUE)
#
#   graph$add_edge("mo", "cat", "output1", "input1")
#   graph$add_edge("mo", "cat", "output2", "input2")
#   graph$add_edge("mo", "cat", "output2", "input3")
#
#
#   graph2$add_edge("mo", "cat", "output1", "input2")
#   graph2$add_edge("mo", "cat", "output2", "input1")
#
#
#
#   task = tsk("iris")
#
#   net1 = graph$train(task)[[1L]]$network
#   net2 = graph2$train(task)[[1L]]$network
#
#   x = torch_randn(1, 4)
#   observed1 = net1(list(num = x))
#   observed2 = net2(list(num = x))
#   expected = 2 * x
#   expect_true(torch_equal(observed, expected))
#
#
# })



