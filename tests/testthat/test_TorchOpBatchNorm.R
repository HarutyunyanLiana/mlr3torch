test_that("TorchOpBatchNorm works", {
  task = tsk("iris")
  op = top("batch_norm")
  for (i in seq_len(3)) {
    param_vals = list(
      eps = runif(1, 0, 0.001),
      momentum = runif(1),
      affine = sample(c(TRUE, FALSE), 1),
      track_running_stats = sample(c(TRUE, FALSE), 1)
    )

    ndim = sample(2:5, 1)

    dims = sample(10, ndim, TRUE)
    inputs = list(input = invoke(torch_randn, .args = dims))

    args = list(num_features = inputs$input$shape[2L])

    op$param_set$values = insert_named(op$param_set$values, param_vals)

    expect_torchop(
      op = op,
      inputs = inputs,
      task = task,
      "nn_batch_norm_",
      exclude = c(
        "num_features" # inferred
      )
    )
  }
})
