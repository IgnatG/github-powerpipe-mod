dashboard "github_admin_dashboard" {  
  title = "GitHub - Admin Dashboard"
  container {
    card {
      query = query.github_total_repositories
      width = 3
      type = "alert"
    }

    card {
      query = query.github_total_repository_branches
      width = 3
      type  = "alert" 
    }

    card {
      query = query.github_total_repositories_without_description
      width = 3
      type  = "alert" 
    }

    card {
      query = query.github_total_archived_repositories
      width = 3
      type = "info"
    }
  }
  
  container {
    table {
      title = "Glue Job repositories"
      query = query.github_wild_repositories
      args = {
        repo = "https://github.com/UKHSA-Internal/edap%glue%"
      }
    }
  }

  container {
    table {
      title = "Lambda repositories"
      query = query.github_wild_repositories
      args = {
        repo = "https://github.com/UKHSA-Internal/edap%lambda%"
      }
    }
  }

  container {
    table {
      title = "Branch Counts by Repository"
      query = query.github_branches_by_repository
    }
  }
}

query "github_total_repositories" {
  sql = <<-EOQ
      SELECT
        COUNT(*) AS "Total repositories"
      FROM
        github_my_repository
      WHERE
        url LIKE 'https://github.com/UKHSA-Internal/edap%'
    EOQ
}

query "github_total_repository_branches" {
  sql = <<-EOQ
    WITH repositories AS (
      SELECT
        REPLACE(url, 'https://github.com/', '') AS repository_full_name
      FROM
        github_my_repository
      WHERE
        is_archived = false
        AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
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
      SUM(branch_count) AS "Total branches"
    FROM
      repositories r
      LEFT JOIN branch_counts b
      ON r.repository_full_name = b.repository_full_name
  EOQ
}

query "github_total_repositories_without_description" {
  sql = <<-EOQ
      SELECT
        COUNT(*) AS "Total Repositories without description"
      FROM
        github_my_repository
      WHERE
        is_archived = false
        AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
        AND (description = 'This is a description of the repo' OR description = '')
      LIMIT 10
    EOQ
}

query "github_total_archived_repositories" {
  sql = <<-EOQ
      SELECT
        COUNT(*) AS "Total Archived Repositories"
      FROM
        github_my_repository
      WHERE
        url LIKE 'https://github.com/UKHSA-Internal/edap%'
        AND is_archived = true
    EOQ
}


query "github_wild_repositories" {
  sql = <<-EOQ
      WITH repositories AS (
        SELECT
          REPLACE(url, 'https://github.com/', '') AS repository_full_name,
          url,
          pushed_at,
          primary_language ->> 'name' as language,
          disk_usage,
          is_archived
        FROM
          github_my_repository
        WHERE
          is_archived = false
          AND url LIKE $1
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
        TO_CHAR(r.pushed_at, 'DD-MM-YYYY HH24:MI:SS') AS "Last Push",
        COALESCE(r.language, 'Unknown') AS "Language",
        ROUND((CAST(r.disk_usage AS NUMERIC) / 1024), 2) || ' Mb' AS "Repository size (MB)",
        CASE
          WHEN r.is_archived THEN 'Yes'
          ELSE 'No'
        END AS "Is Archived",
        COALESCE(b.branch_count, 0) AS "Total Branches"
      FROM
        repositories r
      LEFT JOIN branch_counts b
        ON r.repository_full_name = b.repository_full_name
      ORDER BY
        "Total Branches" DESC;
    EOQ

    param "repo" {
      default = ""
    }
}

query "github_branches_by_repository" {
  sql = <<-EOQ
      WITH repositories AS (
        SELECT
          REPLACE(url, 'https://github.com/', '') AS repository_full_name,
          url,
          pushed_at,
          primary_language ->> 'name' as language,
          disk_usage,
          is_archived
        FROM
          github_my_repository
        WHERE
          is_archived = false
          AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
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
        TO_CHAR(r.pushed_at, 'DD-MM-YYYY HH24:MI:SS') AS "Last Push",
        COALESCE(r.language, 'Unknown') AS "Language",
        ROUND((CAST(r.disk_usage AS NUMERIC) / 1024), 2) || ' Mb' AS "Repository size (MB)",
        CASE
          WHEN r.is_archived THEN 'Yes'
          ELSE 'No'
        END AS "Is Archived",
        COALESCE(b.branch_count, 0) AS "Total Branches"
      FROM
        repositories r
      LEFT JOIN branch_counts b
        ON r.repository_full_name = b.repository_full_name
      ORDER BY
        "Total Branches" DESC;
    EOQ
}