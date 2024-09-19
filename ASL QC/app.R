library(shiny)
library(shinydashboard)
library(DT)
library(base64enc)

# UI
ui <- dashboardPage(
    dashboardHeader(title = "Image Grading App"),
    dashboardSidebar(
        sidebarMenu(
            textInput("dir_path", "Enter Directory Path:"),
            actionButton("loadDir", "Load Directory"),
            br(),
            br(),
            actionButton("saveCSV", "Save to CSV")
        )
    ),
    dashboardBody(
        fluidRow(
            column(width = 3,
                   box(width = NULL, solidHeader = TRUE,
                       title = "Data Frame",
                       DTOutput("grading_table")
                   )
            ),
            column(width = 9,
                   box(width = NULL, height = "600px",
                       title = "Image Preview",
                       uiOutput("image_preview")
                   )
            )
        ),
        fluidRow(
            column(width = 12,
                   box(width = NULL,
                       actionButton("cbf", "CBF"),
                       actionButton("vascular", "Vascular"),
                       actionButton("artifact", "Artifact"),
                       actionButton("unknown", "Unknown"),
                       actionButton("previous", "Previous"),
                       actionButton("next_image", "Next")
                   )
            )
        )
    )
)

# Server
server <- function(input, output, session) {
    values <- reactiveValues(
        dir_path = NULL,
        image_files = NULL,
        current_index = 1,
        grading_data = data.frame(filename = character(), grading = character(), stringsAsFactors = FALSE)
    )
    
    observeEvent(input$loadDir, {
        values$dir_path <- input$dir_path
        if (dir.exists(values$dir_path)) {
            values$image_files <- list.files(values$dir_path, pattern = "\\.(jpg|jpeg)$", full.names = TRUE)
            values$current_index <- 1
            values$grading_data <- data.frame(
                filename = basename(values$image_files),
                grading = rep("", length(values$image_files)),
                stringsAsFactors = FALSE
            )
        } else {
            showNotification("Invalid directory path", type = "error")
        }
    })
    
    output$image_preview <- renderUI({
        req(values$image_files)
        if (length(values$image_files) > 0) {
            current_file <- values$image_files[values$current_index]
            img_data <- base64encode(readBin(current_file, "raw", file.info(current_file)$size))
            tags$figure(
                style = "width: 100%; height: 500px; display: flex; flex-direction: column; justify-content: center; align-items: center;",
                tags$img(src = paste0("data:image/jpeg;base64,", img_data), 
                         style = "max-width: 100%; max-height: 90%; object-fit: contain;"),
                tags$figcaption(basename(current_file), style = "text-align: center; margin-top: 10px;")
            )
        }
    })
    
    observeEvent(input$cbf, {
        updateGrading("CBF")
    })
    
    observeEvent(input$vascular, {
        updateGrading("VASCULAR")
    })
    
    observeEvent(input$artifact, {
        updateGrading("ARTIFACT")
    })
    
    observeEvent(input$unknown, {
        updateGrading("UNKNOWN")
    })
    
    updateGrading <- function(grade) {
        values$grading_data$grading[values$current_index] <- grade
        values$current_index <- min(values$current_index + 1, length(values$image_files))
    }
    
    observeEvent(input$previous, {
        values$current_index <- max(values$current_index - 1, 1)
    })
    
    observeEvent(input$next_image, {
        values$current_index <- min(values$current_index + 1, length(values$image_files))
    })
    
    output$grading_table <- renderDT({
        req(values$grading_data)
        total_rows <- nrow(values$grading_data)
        start_row <- max(1, values$current_index - 5)
        end_row <- min(total_rows, start_row + 9)
        
        if (end_row - start_row < 9) {
            start_row <- max(1, end_row - 9)
        }
        
        subset_data <- values$grading_data[start_row:end_row, ]
        
        datatable(
            subset_data,
            options = list(
                pageLength = 10,
                searching = FALSE,
                lengthChange = FALSE,
                info = FALSE,
                paging = FALSE
            ),
            rownames = FALSE
        ) %>%
            formatStyle(
                'filename',
                target = 'row',
                backgroundColor = styleEqual(values$grading_data$filename[values$current_index], 'lightblue')
            )
    })
    
    observeEvent(input$saveCSV, {
        req(values$grading_data)
        write.csv(values$grading_data, file = file.path(values$dir_path, "grading_results.csv"), row.names = FALSE)
        showNotification("Results saved to CSV", type = "message")
    })
}

# Run the app
shinyApp(ui, server)