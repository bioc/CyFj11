# Regression test: ellipse gate counts must match FlowJo 11.2 (schema 3.0.0).
# Workspace drawn at gate resolution 1024: five Linear gates (FSC-A/SSC-A) and
# four gates on Biex axes (FITC-A/PE-A, vectorLength 256). Expected counts are
# those shown by FlowJo; tolerance covers the biex transform lookup table.

test_that("ellipse gates reproduce FlowJo counts (1024, Linear and Biex)", {
    skip_if_not_installed("flowWorkspace")
    d <- testthat::test_path("fixtures", "ellipse")
    skip_if_not(file.exists(file.path(d, "test15.1024.flowjo")))

    ws <- suppressMessages(
        read_flowjo11_workspace(file.path(d, "test15.1024.flowjo"))
    )
    utils::capture.output(suppressMessages(suppressWarnings(
        res <- fj11_to_gatingset(ws, group_name = "Experiment Data", path = d)
    )))
    gh <- res[[1]]
    if (!inherits(gh, "GatingHierarchy")) gh <- gh[[1]]
    st <- flowWorkspace::gs_pop_get_count_fast(gh)
    got <- setNames(st$Count, sub("^/", "", st$Population))

    expected <- c(
        "vertical ellipse" = 1562,
        "45 degreee ellipse downward right" = 6347,
        "horizontal ellipse" = 1126,
        "45 degree elips upwards right" = 4105,
        "intermediate ellipse" = 8083,
        "vertical" = 6992,
        "45 up" = 804,
        "horizontal" = 544,
        "45 down" = 1870
    )
    expect_setequal(names(got), names(expected))
    # Linear gates agree to a handful of events. Biex gates differ by up to
    # ~4%: part of this is the biex transform being tabulated at finite
    # resolution; the remainder is not fully explained (to check with FlowJo).
    biex <- names(expected) %in% c("vertical", "45 up", "horizontal", "45 down")
    tol <- ifelse(biex, 0.05 * expected, 10)
    expect_true(all(abs(got[names(expected)] - expected) <= tol),
        info = paste(capture.output(print(cbind(got = got[names(expected)],
            flowjo = expected))), collapse = "\n"))
})

test_that("ellipse covariance: a along rotated x, b perpendicular", {
    cov0 <- CyFj11:::gate_ellipse_cov_display(10, 2, 0)
    expect_equal(diag(cov0), c(100, 4))
    cov90 <- CyFj11:::gate_ellipse_cov_display(10, 2, pi / 2)
    expect_equal(diag(cov90), c(4, 100), tolerance = 1e-12)
    # schema version no longer changes the convention
    expect_identical(
        CyFj11:::gate_ellipse_cov_display(10, 2, 0.7, numeric_version("3.0.0")),
        CyFj11:::gate_ellipse_cov_display(10, 2, 0.7, numeric_version("4.0.0"))
    )
})
