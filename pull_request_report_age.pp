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
    select
      count(*) as value,
      'Open PRs' as label
    from
      github_my_repository r
      join github_pull_request p on p.repository_full_name = r.name_with_owner
    where
      p.state = 'OPEN';
  EOQ
}


query "open_pull_request_table" {
  sql = <<-EOQ
    select
      '#' || number || ' ' || title as "PR",
      repository_full_name as "Repository",
      now()::date - p.created_at::date as "Age in Days",
      mergeable as "Mergeable State",
      author ->> 'login' as "Author",
      author ->> 'url' as "author_url",
      case
        when author_association = 'NONE' then 'External'
        else initcap(author_association)
      end as "Author Association",
      p.url,
      r.url as repo_url
    from
      github_my_repository r
      join github_pull_request p on p.repository_full_name = r.name_with_owner
    where
      p.state = 'OPEN'
    order by
      "Age in Days" desc;
  EOQ
}