#######################
# SETUP AND FUNCTIONS #
#######################
`%>%` = magrittr::`%>%`

#' Test a list of segments and simulation values
#'
#' @aliases test_fit
#' @keywords internal
#' @param model A list of (unnamed) formulas
#' @param simulated Parameter values to be used for simulation.
test_fit = function(model, simulated) {
  testthat::skip_if(is.null(options("test_mcp_fits")[[1]]),
                    "This time-consuming test is only run locally before release.")

  # Simulate
  empty = mcp(model, sample = FALSE, par_x = "x")
  data = tibble::tibble(
    x = 1:200,  # Needs to be reasonably high to get a correct estimate
    y = do.call(empty$simulate, c(list(x = 1:200), simulated))
  )

  # Fit
  quiet_out = purrr::quietly(mcp)(model, data, par_x = "x")
  fit <<- quiet_out$result

  # Check parameter recovery
  results_table = purrr::quietly(fixef)(fit)$result
  success = all(results_table$match == "OK")
  if (success == FALSE) {
    print(results_table)
  }
  testthat::expect_true(success, model)
}


#' Apply `test_fit` to each element of this list
#'
#' @aliases apply_test_fit
#' @keywords internal
#' @param all_modelss A list of lists. Each sub-list is an unnamed list of
#'   formulas with one named entry called "simulated" with parameter values to
#'   be used for simulation.
apply_test_fit = function(all_models, code) {
  for (this in all_models) {
    # Split into formulas and simulation values
    simulated = this[names(this) == "simulated"][[1]]
    model = this[names(this) == ""]

    # Test!
    testthat::test_that(
      test_fit(model, simulated),
      code = code
    )
  }
}




#################
# TEST GAUSSIAN #
#################

models_gauss = list(
  # Simple
  list(y ~ 1,
       ~ 1,
       simulated = list(
         int_1 = 10,
         int_2 = 20,
         sigma_1 = 5,
         cp_1 = 100)),

  # A lot of terms
  list(y ~ 1 + x + sin(x),
       ~ rel(1) + rel(x),
       ~ 0,
       simulated = list(
         cp_1 = 70,
         cp_2 = 140,
         int_1 = 10,
         x_1 = 0.5,
         x_2 = -1,
         x_1_sin = 5,
         sigma_1 = 5,
         int_2 = -50)),

  # Simple AR
  list(y ~ 1 + ar(1),
       simulated = list(
         int_1 = 30,
         ar1_1 = 0.7,
         sigma_1 = 10
       )),

  # Larger AR
  list(y ~ 1 + ar(2),
       ~ 0 + x + ar(1),
       ~ 0,
       simulated = list(
         cp_1 = 80,
         cp_2 = 140,
         int_1 = -20,
         sigma_1 = 5,
         ar1_1 = 0.7,
         ar2_1 = -0.4,
         x_2 = 0.5,
         ar1_2 = 0.5
       ))

  # Sigma here

)

apply_test_fit(models_gauss, "Gaussian fit")
