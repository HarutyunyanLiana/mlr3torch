test_that("LearnerClassifTorch works with nn_module as architecture", {
  task = tsk("iris")
  task$row_roles$early_stopping = sample.int(task$nrow, 10)

  module = nn_module(
    initialize = function(task) {
      self$net = nn_sequential(
        nn_tab_tokenizer(4, cardinalities = integer(), d_token = 3, bias = TRUE, cls = FALSE),
        nn_flatten(),
        nn_linear(12, 10),
        nn_relu(),
        nn_linear(10, length(task$target_names))
      )
    },
    forward = function(x) {
      self$net(x)
    }
  )




  l = lrn("classif.torch", optimizer = "adam", loss = "cross_entropy", module = module,
    opt.lr = 0.1, device = "cpu", epochs = 2L, batch_size = 16L,
    measures_valid = msr("classif.acc")
  )
  l$train(task)
  expect_error(l$train(task), regexp = NA)
  expect_error(l$predict(task), regexp = NA)

  net = nn_sequential$new(nn_linear(4, 4))
  expect_error(
    lrn("classif.torch", network = net, optimizer = "adam", loss = "cross_entropy"),
    regexp = "The network must be initialized by calling the function (and not with '$new()').",
    fixed = TRUE
  )
})
