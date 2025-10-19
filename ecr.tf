resource "aws_ecr_repository" "dca-app" {
    name = "dca-app"

    tags = {
        Name = "dca-app-container"
    }
}
