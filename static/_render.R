render_slides <- function(url) {
  pkg_chr <- c("magick", "stringr", "fs")

  pkg_install_load <- function(pkg) {
    available_pkg <- installed.packages()[, "Package"]
    missing_pkg <- pkg[!(pkg %in% available_pkg)]
    if (length(missing_pkg) > 0) {
      backtick <- function(x) {
        vapply(x, function(y) paste0("`", y, "`"), character(1))
      }
      fmt_pkg <- paste(backtick(missing_pkg), collapse = ", ")
      msg <- sprintf("Do you want to install %s to proceed?", fmt_pkg)
      prompt <- menu(c("Yep", "Nope"), title = msg)
      if (prompt == 1) {
        install.packages(pkg_chr, dependencies = FALSE)
      } else {
        stop(sprintf("Missing packages: %s", fmt_pkg), call. = FALSE)
      }
    }
    invisible(lapply(pkg, require, quietly = TRUE, character.only = TRUE))
  }

  pkg_install_load(pkg_chr)
  
  link <- url
  file_name <- basename(link)
  dir_name <- dirname(link)
  pdf_dir <- path_expand(paste0("~/Desktop/ETC3250-",
    gsub(".html", "", file_name)))
  dir_create(pdf_dir)

  kunoichi_url <- paste0(dir_name, "/libs/remark-css/kunoichi.css")
  ninjutsu_url <- paste0(dir_name, "/libs/remark-css/ninjutsu.css")
  kunoichi_temp <- paste0(pdf_dir, "/libs/remark-css/kunoichi.css")
  ninjutsu_temp <- paste0(pdf_dir, "/libs/remark-css/ninjutsu.css")
  dir_create(paste0(pdf_dir, "/libs/remark-css"))
  download.file(kunoichi_url, kunoichi_temp, checkOK = FALSE)
  download.file(ninjutsu_url, ninjutsu_temp, checkOK = FALSE)

  mystyle_url <- paste0(dir_name, "/mystyle.css")
  mystyle_temp <- paste0(pdf_dir, "/mystyle.css")
  download.file(mystyle_url, mystyle_temp, checkOK = FALSE)

  content <- readLines(link)
  files_dir <- paste0("/", gsub(".html", "", file_name), "_files/")
  dir_create(paste0(pdf_dir, files_dir, "figure-html"))
  png_pattern <- "(figure-html)(.*)\\.png"
  png_lines <- grep(png_pattern, content)
  png_tags <- content[png_lines]
  png_files <- str_extract(str_extract(
    png_tags, "(figure-html)(.*)\\.png"), png_pattern)
  for (i in png_files) {
    dl_url <- paste0(dir_name, files_dir, i)
    download.file(dl_url, paste0(pdf_dir, files_dir, i), checkOK = FALSE)
  }

  images_dir <- paste0(dir_name, "/images/")
  images_temp <- paste0(pdf_dir, "/images/")
  dir_create(paste0(pdf_dir, "/images"))
  img_pattern <- "images/"
  img_lines <- grep(img_pattern, content)
  img_tags <- content[img_lines]
  img_files <- str_extract(img_tags, "(images/)(.*)\\.(png|jpg|jpeg)")
  for (i in img_files) {
    dl_url <- paste0(dir_name, "/", i)
    download.file(dl_url, paste0(pdf_dir, "/", i), checkOK = FALSE)
  }

  pdf_pattern <- "(http|https)(.*)\\.pdf"
  pdf_lines <- grep(pdf_pattern, content)
  pdf_tags <- content[pdf_lines]
  pdf_files <- str_extract(str_extract(
    pdf_tags, "src=\"(http|https)(.*)\\.pdf"), pdf_pattern)
  for (i in seq_along(pdf_tags)) {
    temp_png <- tempfile(tmpdir = pdf_dir, fileext = ".png")
    image_write(image_read(pdf_files[i], density = 300), temp_png, 
      format = "png", density = 300)
    content[pdf_lines][i] <- str_replace_all(pdf_tags[i], pdf_files[i],
      basename(temp_png))
  }
  dest_file <- paste(pdf_dir, file_name, sep = "/")
  file_conn <- file(dest_file)
  writeLines(content, file_conn)
  close(file_conn)
}
