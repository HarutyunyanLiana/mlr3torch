#' @title Represent a Model with Meta-Info
#'
#' @description
#' Represents a model; possibly a complete model, possibly one in the process of being built up.
#'
#' This model takes input tensors of shapes `shapes_in` and
#' pipes them through `graph`. Input shapes get mapped to input channels of `graph`.
#' Output shapes are named by the output channels of `graph`; it is also possible
#' to represent no-ops on tensors, in which case names of input and output should be identical.
#'
#' `ModelDescriptor` objects typically represent partial models being built up, in which case the `.pointer` slot indicates
#' a specific point in the graph that produces a tensor of shape `.pointer_shape`, on which the graph should be extended.
#'
#' It is allowed for the `graph` in this structure to be modified by-reference in different parts of the code.
#' However, these modifications may never add edges with elements of the `Graph` as destination. In particular, no element
#' of `graph$input` may be removed by reference, e.g. by adding an edge to the `Graph` that has the input channel of a `PipeOp`
#' that was previously without parent as its destination.
#'
#' @param graph ([`Graph`][mlr3pipelines::Graph])\cr
#'   `Graph` of [`PipeOpModule`] operators.
#' @param ingress (uniquely named `list` of `TorchIngressToken`)\cr
#'   List of inputs that go into `graph`. Names of this must be a subset of `graph$input$name`.
#' @param task ([`Task`][mlr3::Task])\cr
#'   (Training)-Task for which the model is being built. May be necessary for for some aspects of what loss to use etc.
#' @param optimizer ([`TorchOptimizer`] | `NULL`)\cr
#'   Additional info: what optimizer to use.
#' @param loss ([`TorchLoss`] | `NULL`)\cr
#'   Additional info: what loss to use.
#' @param callbacks (`list`)\cr
#'   Callbacks.
#' @param .pointer (`character(2)` | `NULL`)\cr
#'   Indicating an element on which a model is. Points to an output channel within `graph`:
#'   Element 1 is the `PipeOp`'s id and element 2 is that `PipeOp`'s output channel.
#' @param .pointer_shape (`integer` | `NULL`)\cr
#'   Shape of the output indicated by `.pointer`.
#' @return a `ModelDescriptor`.
ModelDescriptor = function(graph, ingress, task, optimizer = NULL, loss = NULL, callbacks = list(), .pointer = NULL, .pointer_shape = NULL) {
  assert_r6(graph, "Graph")
  innames = graph$input$name  # graph$input$name access is slow

  assert_list(ingress, min.len = 1, types = "TorchIngressToken", names = "unique", any.missing = FALSE)

  # conditions on ingress: maps shapes_in to graph$input$name
  assert_names(names(ingress), subset.of = innames)

  assert_r6(task, "Task")

  assert_r6(optimizer, "TorchOptimizer", null.ok = TRUE)
  assert_r6(loss, "TorchLoss", null.ok = TRUE)
  assert_list(callbacks, any.missing = FALSE, types = "R6ClassGenerator")

  if (!is.null(.pointer)) {
    assert_integerish(.pointer_shape, len = 2)
    assert_choice(.pointer[[1]], names(graph$pipeops))
    assert_choice(.pointer[[2]], graph$pipeops[[.pointer[[1]]]]$output$name)
  }

  structure(list(
    graph = graph,
    ingress = ingress,
    task = task,
    optimizer = optimizer,
    loss = loss,
    callbacks = callbacks,
    .pointer = .pointer,
    .pointer_shape = .pointer_shape
  ), class = "ModelDescriptor")
}

#' @export
print.ModelDescriptor = function(x, ...) {
  shape_to_str = function(x) {
    shapedescs = map_chr(x, function(y) paste0("(", paste(y, collapse = ",", recycle0 = TRUE), ")"))
    paste0("[", paste(shapedescs, collapse = ";", recycle0 = TRUE), "]")
  }
  cat(sprintf("ModelDescriptor (%s ops):\n%s\noptimizer: %s\nloss: %s\n%s callbacks%s\n",
    length(x$graph$pipeops),
    shape_to_str(map(x$ingress, "shape")),
    if (is.null(x$optimizer)) "N/A" else if (is.null(x$optimizer$label)) "unknown" else x$optimizer$label,
    if (is.null(x$loss)) "N/A" else if (is.null(x$loss$label)) "unknown" else x$loss$label,
    length(x$callbacks),
    if (is.null(x$.pointer)) "" else sprintf("\n.pointer: %s %s", paste(x$.pointer, collapse = "."), shape_to_str(list(x$.pointer_shape)))
  ))
}


#' @title Union of ModelDescriptor
#'
#' @description
#' Creates the union of multiple [`ModelDescriptor`]s.
#'
#' `graph`s are combinded (if they are not identical to begin with). `PipeOp`s with the same ID must be identical.
#' No new input edgees may be added to `PipeOp`s. (This last requirement is not theoretically necessary, but since
#' we assume that ModelDescriptor is being built from beginning to end (i.e. `PipeOp`s never get new ancestors) we
#' can make this assumption and simplify things. Otherwise we'd need to treat "..."-inputs special.)
#'
#' Modifies the first entry's `graph` by reference.
#'
#' Drops `.pointer` / `.pointer_shape` entries.
#'
#' @param mds1 (`list` of `ModelDescriptor`)
#'   The first [`ModelDescriptor`].
#' @param mds2 (`list` of `ModelDescriptor`)
#'   The second [`ModelDescriptor`].
#' @return a `ModelDescriptor`.
#' @export
model_descriptor_union = function(mds1, mds2) {
  assert_class(mds1, "ModelDescriptor")
  assert_class(mds2, "ModelDescriptor")
  graph = mds1$graph

  # if graphs are identical, we don't need to worry about copying stuff
  if (!identical(mds1$graph, mds2$graph)) {
    # PipeOps that have the same ID that occur in both graphs must be identical.
    common_names = intersect(names(graph$pipeops), names(mds2$graph$pipeops))
    assert_true(identical(graph$pipeops[common_names], mds2$graph$pipeops[common_names]))

    # copy all PipeOps that are in mds2 but not in mds1
    graph$pipeops = c(graph$pipeops, mds2$graph$pipeops[setdiff(names(mds2$graph$pipeops), common_names)])

    # clear param_set cache
    graph$.__enclos_env__$private$.param_set = NULL

    # edges that are in mds2's graph that were not in mds1's graph
    new_edges = mds2$graph$edges[!graph$edges, on = c("src_id", "src_channel", "dst_id", "dst_channel")]

    # IDs and channel names that get new input edges. These channels must not already have incoming edges in mds1.
    new_input_edges = unique(new_edges[, c("dst_id", "dst_channel"), with = FALSE])

    forbidden_edges = graph$edges[new_input_edges, on = c("dst_id", "dst_channel"), nomatch = NULL]
    if (nrow(forbidden_edges)) stop(sprintf("PipeOp(s) %s have differing incoming edges in mds1 and mds2.", paste(forbidden_edges$dst_id, collapse = ", ")))
    graph$edges = rbind(graph$edges, new_edges)
  }

  merge_assert_unique = function(a, b, .var.name) {
    common_names = intersect(names(a), names(b))
    assert_true(identical(a[common_names], b[common_names]), .var.name = sprintf("common entries of %s of ModelDescriptors being merged are identical"))
    a[names(b)] = b
    a
  }

  coalesce_assert_id = function(a, b, .var.name) {
    if (!is.null(a) && !is.null(b) && !identical(a, b)) {
      stop(sprintf("%s of two ModelDescriptors being merged disagree."))
    }
    a %??% b
  }

  # merge tasks: this is pretty much exactly what POFU does, so we use it in the non-trivial case.
  if (identical(mds1$task, mds2$task)) {
    task = mds1$task
  } else {
    task = PipeOpFeatureUnion$new()$train(list(mds1$task, mds2$task))[[1]]
  }

  ModelDescriptor(
    graph = graph,
    ingress = merge_assert_unique(mds1$ingress, mds2$ingress, .var.name = "ingress"),
    task = task,
    optimizer = coalesce_assert_id(mds1$optimizer, mds2$optimizer, .var.name = "optimizer"),
    loss = coalesce_assert_id(mds1$loss, mds2$loss, .var.name = "loss"),
    callbacks = merge_assert_unique(mds1$callbacks, mds2$callbacks, .var.name = "callbacks")
  )
}

