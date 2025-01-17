% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/LearnerClassifTorch.R
\name{mlr_learners_classif.torch}
\alias{mlr_learners_classif.torch}
\alias{LearnerClassifTorch}
\title{LearnerTorchClassif}
\description{
This implements a custom neural network.
}
\section{Super classes}{
\code{\link[mlr3:Learner]{mlr3::Learner}} -> \code{\link[mlr3:LearnerClassif]{mlr3::LearnerClassif}} -> \code{\link[mlr3torch:LearnerClassifTorchAbstract]{mlr3torch::LearnerClassifTorchAbstract}} -> \code{LearnerClassifTorch}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-LearnerClassifTorch-new}{\code{LearnerClassifTorch$new()}}
\item \href{#method-LearnerClassifTorch-clone}{\code{LearnerClassifTorch$clone()}}
}
}
\if{html}{\out{
<details><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="base_learner"><a href='../../mlr3/html/Learner.html#method-Learner-base_learner'><code>mlr3::Learner$base_learner()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="format"><a href='../../mlr3/html/Learner.html#method-Learner-format'><code>mlr3::Learner$format()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="help"><a href='../../mlr3/html/Learner.html#method-Learner-help'><code>mlr3::Learner$help()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="predict"><a href='../../mlr3/html/Learner.html#method-Learner-predict'><code>mlr3::Learner$predict()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="predict_newdata"><a href='../../mlr3/html/Learner.html#method-Learner-predict_newdata'><code>mlr3::Learner$predict_newdata()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="print"><a href='../../mlr3/html/Learner.html#method-Learner-print'><code>mlr3::Learner$print()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="reset"><a href='../../mlr3/html/Learner.html#method-Learner-reset'><code>mlr3::Learner$reset()</code></a></li>
<li><span class="pkg-link" data-pkg="mlr3" data-topic="Learner" data-id="train"><a href='../../mlr3/html/Learner.html#method-Learner-train'><code>mlr3::Learner$train()</code></a></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-LearnerClassifTorch-new"></a>}}
\if{latex}{\out{\hypertarget{method-LearnerClassifTorch-new}{}}}
\subsection{Method \code{new()}}{
Initializes an instance of this \link[R6:R6Class]{R6} class.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{LearnerClassifTorch$new(
  module,
  param_set = NULL,
  optimizer = t_opt("adam"),
  loss = t_loss("cross_entropy"),
  param_vals = list(),
  feature_types = NULL
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{optimizer}}{(\code{character()})\cr
A character string containing the name of the optimizer.
Possible values are \code{torch_reflections$optimizer}.}

\item{\code{loss}}{(\code{character()})\cr
A character string containing the name of the loss function
For possible values see \code{torch_reflections$loss}.}

\item{\code{param_vals}}{(named \code{list()})\cr
The initial parameters for the object.}

\item{\code{feature_types}}{(\code{character()})\cr
The feature types the learner supports. The default is all feature types.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-LearnerClassifTorch-clone"></a>}}
\if{latex}{\out{\hypertarget{method-LearnerClassifTorch-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{LearnerClassifTorch$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
