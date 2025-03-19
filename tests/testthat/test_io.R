library(testthat)

# NOTE: this seems like a weird standard for testing. Should I library(mypackage)?

test_that("fail gracefully for misconfigured persona file", {
    skip("Not yet written")

    test_file <- tempfile(fileext = ".csv")

    persona_nonames <- sample(0:10, size = 87, replace = TRUE)

    unlink(test_file)
})


test_that("saving and loading a single persona", {
    test_file <- tempfile(fileext = ".csv")

    config <- biodt.recreation::load_config()
    persona <- setNames(
        sample(0:10, size = 87, replace = TRUE),
        config[["Name"]]
    )

    biodt.recreation::save_persona(persona, test_file, "persona")

    expect_true(file.exists(test_file))

    loaded_persona <- biodt.recreation::load_persona(test_file)

    expect_equal(loaded_persona, persona)

    unlink(test_file)
})

test_that("appending a person", {
    test_file <- tempfile(fileext = ".csv")

    config <- biodt.recreation::load_config()
    persona1 <- setNames(
        sample(0:10, size = 87, replace = TRUE),
        config[["Name"]]
    )
    persona2 <- setNames(
        sample(0:10, size = 87, replace = TRUE),
        config[["Name"]]
    )

    biodt.recreation::save_persona(persona1, test_file, "persona1")
    biodt.recreation::save_persona(persona2, test_file, "persona2")

    expect_true(file.exists(test_file))

    loaded_persona1 <- biodt.recreation::load_persona(test_file, name = "persona1")
    loaded_persona2 <- biodt.recreation::load_persona(test_file, name = "persona2")

    expect_equal(loaded_persona1, persona1)
    expect_equal(loaded_persona2, persona2)

    unlink(test_file)
})

# TODO:
# 1. Test multiple persona in a single file
# 2. Test that overwriting an existing persona works
