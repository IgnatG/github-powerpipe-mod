dashboard "github_branch_counts_dashboard" {  
  container {
    card {
      title = "Total Repositories"
      sql = <<EOQ
        SELECT
          COUNT(*) AS "Total repositories"
        FROM
          github_my_repository
        WHERE
          url LIKE 'https://github.com/UKHSA-Internal/edap%'
      EOQ
      width = 3
    }

    card {
      title = "Total Branches"
      sql = <<EOQ
        WITH repositories AS (
          SELECT
            REPLACE(url, 'https://github.com/', '') AS repository_full_name
          FROM
            github_my_repository
          WHERE
            url LIKE 'https://github.com/UKHSA-Internal/edap%'
        )
        SELECT
          COUNT(*) AS total_branches
        FROM
          github_branch
        WHERE
          repository_full_name IN (
            SELECT
              repository_full_name
            FROM
              repositories
          )
      EOQ
      width = 3
    }

    card {
      title = "Archived Repositories"
      sql = <<EOQ
        SELECT
          COUNT(*) AS archived_repositories
        FROM
          github_my_repository
        WHERE
          url LIKE 'https://github.com/UKHSA-Internal/edap%'
          AND is_archived = true
      EOQ
      width = 3
    }

    card {
      title = "Repositories without Descriptions"
      sql = <<EOQ
        SELECT
          COUNT(*) AS "Repositories without description"
        FROM
          github_my_repository
        WHERE
          url LIKE 'https://github.com/UKHSA-Internal/edap%'
          AND (description IS NULL OR description = 'This is a description of the repo')
      EOQ
      width = 3
    }
  }

      chart {
      title = "Column Chart - Branch Counts by Repository"
      type = "column"
      width = 12
      sql = <<EOQ
        WITH repositories AS (
          SELECT
            url,
            REPLACE(url, 'https://github.com/', '') AS repository_full_name
          FROM
            github_my_repository
          WHERE
            url LIKE 'https://github.com/UKHSA-Internal/edap%'
        ),
        branch_counts AS (
          SELECT
            repository_full_name,
            COUNT(name) AS branch_count
          FROM
            github_branch
          WHERE
            repository_full_name IN (
              SELECT
                repository_full_name
              FROM
                repositories
            )
          GROUP BY
            repository_full_name
        )
        SELECT
          r.url AS "Repository URL",
          COALESCE(b.branch_count, 0) AS branch_count
        FROM
          repositories r
          LEFT JOIN branch_counts b
          ON r.repository_full_name = b.repository_full_name
        ORDER BY
          branch_count DESC
        LIMIT 20;
      EOQ
    }

  container {
    table {
      title = "Table - Branch Counts by Repository"
      width = 6
      sql = <<EOQ
        WITH repositories AS (
          SELECT
            REPLACE(url, 'https://github.com/', '') AS repository_full_name,
            url
          FROM
            github_my_repository
          WHERE
            url LIKE 'https://github.com/UKHSA-Internal/edap%'
        ),
        branch_counts AS (
          SELECT
            repository_full_name,
            COUNT(name) AS branch_count
          FROM
            github_branch
          WHERE
            repository_full_name IN (
              SELECT
                repository_full_name
              FROM
                repositories
            )
          GROUP BY
            repository_full_name
        )
        SELECT
          r.url AS "Repository URL",
          COALESCE(b.branch_count, 0) AS "Total Branches"
        FROM
          repositories r
          LEFT JOIN branch_counts b
          ON r.repository_full_name = b.repository_full_name
        ORDER BY
          "Total Branches" DESC;
      EOQ
    }
  }
}
