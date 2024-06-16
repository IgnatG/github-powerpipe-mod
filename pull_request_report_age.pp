dashboard "pull_request_open_age_report" {
  title = "GitHub Open Pull Request Age Report"

  tags = merge(local.pull_request_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {
    card {
      query = query.open_pull_request_count
      width = 2
    }

    card {
      query = query.open_pull_request_24_hours_count
      width = 2
      type  = "info"
    }

    card {
      query = query.open_pull_request_30_days_count
      width = 2
      type  = "info"
    }

    card {
      query = query.open_pull_request_30_90_days_count
      width = 2
      type  = "info"
    }

    card {
      query = query.open_pull_request_90_365_days_count
      width = 2
      type  = "info"
    }

    card {
      query = query.open_pull_request_1_year_count
      width = 2
      type  = "info"
    }
  }

  container {
    table {
      title = "Open Pull Requests"
      query = query.open_pull_request_table

      column "url" {
        display = "none"
      }

      column "author_url" {
        display = "none"
      }

      column "repo_url" {
        display = "none"
      }

      column "PR" {
        href = "{{.'url'}}"
        wrap = "all"
      }

      column "Author" {
        href = "{{.'author_url'}}"
      }

      column "Repository" {
        href = "{{.'repo_url'}}"
      }
    }
  }
}

query "open_pull_request_count" {
  sql = <<-EOQ
    SELECT
      count(*) as value,
      'Open PRs' as label
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
  EOQ
}

query "open_pull_request_24_hours_count" {
  sql = <<-EOQ
    SELECT
      '< 24 Hours' as label,
      count(p.*) as value
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND p.created_at > now() - '1 days'::interval
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
  EOQ
}

query "open_pull_request_30_days_count" {
  sql = <<-EOQ
    SELECT
      '1-30 Days' as label,
      count(p.*) as value
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND p.created_at between symmetric now() - '1 days' :: interval AND now() - '30 days' :: interval
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
  EOQ
}

query "open_pull_request_30_90_days_count" {
  sql = <<-EOQ
    SELECT
      '30-90 Days' as label,
      count(p.*) as value
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND p.created_at between symmetric now() - '30 days' :: interval AND now() - '90 days' :: interval
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
  EOQ
}

query "open_pull_request_90_365_days_count" {
  sql = <<-EOQ
    SELECT
      '90-365 Days' as label,
      count(p.*) as value
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND p.created_at between symmetric now() - '90 days' :: interval AND now() - '365 days' :: interval
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
  EOQ
}

query "open_pull_request_1_year_count" {
  sql = <<-EOQ
    SELECT
      '> 1 Year' as label,
      count(p.*) as value
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND p.created_at <= now() - '1 year' :: interval
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
  EOQ
}

query "open_pull_request_table" {
  sql = <<-EOQ
    SELECT
      '#' || number || ' ' || title as "PR",
      repository_full_name as "Repository",
      now()::date - p.created_at::date as "Age in Days",
      now()::date - p.updated_at::date as "Days Since Last Update",
      mergeable as "Mergeable State",
      author ->> 'login' as "Author",
      author ->> 'url' as "author_url",
      case
        when author_association = 'NONE' then 'External'
        else initcap(author_association)
      end as "Author Association",
      p.url,
      r.url as repo_url
    FROM
      github_my_repository r
      JOIN github_pull_request p ON p.repository_full_name = r.name_with_owner
    WHERE
      p.state = 'OPEN'
      AND url LIKE 'https://github.com/UKHSA-Internal/edap%'
    ORDER BY
      "Age in Days" desc
  EOQ
}