#' @title Shows Training Process in the Console
#' @description
#' Prints a progress bar and the metrics for training and validation.
#' @include CallbackTorch.R
#' @export
CallbackTorchProgress = callback_torch(
  on_epoch_begin = function() {
    catf("Epoch %s", self$state$epoch)
    self$pb_train = progress::progress_bar$new(
      total = length(self$state$loader_train),
      format = "Training [:bar]"
    )
  },
  on_batch_end = function() {
    self$pb_train$tick(tokens = list(loss = self$state$last_loss))
  },
  on_before_validation = function() {
    self$pb_valid = progress::progress_bar$new(
      total = length(self$state$loader_valid),
      format = "Validation: [:bar]"
    )
  },
  on_batch_valid_end = function() {
    self$pb_valid$tick(tokens = list(loss = last_loss))
  },
  on_epoch_end = function() {
    scores = list()
    scores$train = self$state$last_scores_train
    scores$valid = self$state$last_scores_valid

    scores = Filter(function(x) length(x) > 0, scores)

    if (!length(scores)) {
      catf("[End of epoch %s]", self$state$epoch)
    } else {
      catf("\n[Summary epoch %s]", self$state$epoch)
      cat("------------------\n")
      for (phase in names(scores)) {
        catf("Measures (%s):", capitalize(phase))
        curscore = scores[[phase]]
        output = sprintf(" * %s = %.2f\n", names(curscore), unlist(curscore))
        cat(paste(output, collapse = ""))
      }
    }
  }
)

