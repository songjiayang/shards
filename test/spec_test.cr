require "minitest/autorun"
require "./test_helper"

module Shards
  class SpecTest < Minitest::Test
    def test_parse_minimal_shard
      spec = Spec.from_yaml("name: shards\nversion: 0.1.0\n")
      assert_equal "shards", spec.name
      assert_equal "0.1.0", spec.version
      assert_nil spec.description
      assert_nil spec.license
      assert_empty spec.authors
    end

    def test_parse_description
      spec = Spec.from_yaml("name: shards\nversion: 0.1.0\ndescription: short description")
      assert_equal "short description", spec.description

      spec = Spec.from_yaml("name: shards\nversion: 0.1.0\ndescription: |\n slightly longer description")
      assert_equal "slightly longer description", spec.description
    end

    def test_parse_license
      spec = Spec.from_yaml("name: shards\nversion: 0.1.0\nlicense: BSD-2-Clause")
      assert_equal "BSD-2-Clause", spec.license
      assert_equal "http://opensource.org/licenses/BSD-2-Clause", spec.license_url

      spec = Spec.from_yaml("name: shards\nversion: 0.1.0\nlicense: http://example.com/LICENSE")
      assert_equal "http://example.com/LICENSE", spec.license
      assert_equal "http://example.com/LICENSE", spec.license_url
    end

    def test_parse_authors
      spec = Spec.from_yaml("name: shards\nversion: 0.1.0\nauthors:\n  - Julien Portalier <julien@portalier.com>\n  - Ary")
      assert_equal 2, spec.authors.size

      assert_equal "Julien Portalier", spec.authors[0].name
      assert_equal "julien@portalier.com", spec.authors[0].email

      assert_equal "Ary", spec.authors[1].name
      assert_nil spec.authors[1].email
    end

    def test_parse_dependencies
      spec = Spec.from_yaml <<-YAML
  name: orm
  version: 1.0.0
  dependencies:
    repo:
      github: user/repo
      version: 1.2.3
    example:
      git: https://example.com/example-crystal.git
      branch: master
    local:
      path: /var/clones/local
      tag: unreleased
  YAML

      assert_equal 3, spec.dependencies.size

      assert_equal "repo", spec.dependencies[0].name
      assert_equal "user/repo", spec.dependencies[0]["github"]
      assert_equal "1.2.3", spec.dependencies[0].version
      assert_nil spec.dependencies[0].refs

      assert_equal "example", spec.dependencies[1].name
      assert_equal "https://example.com/example-crystal.git", spec.dependencies[1]["git"]
      assert_equal "*", spec.dependencies[1].version
      assert_equal "master", spec.dependencies[1].refs

      assert_equal "local", spec.dependencies[2].name
      assert_equal "/var/clones/local", spec.dependencies[2]["path"]
      assert_equal "*", spec.dependencies[2].version
      assert_equal "unreleased", spec.dependencies[2].refs
    end

    def test_parse_development_dependencies
      spec = Spec.from_yaml <<-YAML
  name: orm
  version: 1.0.0
  development_dependencies:
    minitest:
      github: ysbaddaden/minitest.cr
      version: 0.1.4
    webmock:
      git: https://github.com/manastech/webcmok-crystal.git
      branch: master
  YAML

      assert_equal 2, spec.development_dependencies.size

      assert_equal "minitest", spec.development_dependencies[0].name
      assert_equal "ysbaddaden/minitest.cr", spec.development_dependencies[0]["github"]
      assert_equal "0.1.4", spec.development_dependencies[0].version

      assert_equal "webmock", spec.development_dependencies[1].name
      assert_equal "https://github.com/manastech/webcmok-crystal.git", spec.development_dependencies[1]["git"]
      assert_equal "master", spec.development_dependencies[1].refs
    end

    def test_skips_unknown_attributes
      spec = Spec.from_yaml("\nanme: test\ncustom:\n  test: more\nname: test\nversion: 1\n")
      assert_equal "test", spec.name
      assert_equal "1", spec.version

      spec = Spec.from_yaml("\nanme:\nname: test\nversion: 1\n")
      assert_equal "test", spec.name
      assert_equal "1", spec.version
    end

    def test_raises_on_unknown_attributes_if_validating
      ex = assert_raises(ParseError) { Spec.from_yaml("anme:", validate: true) }
      assert_match "unknown attribute: anme", ex.message
    end

    def test_raises_when_required_attributes_are_missing
      ex = assert_raises(ParseError) { Spec.from_yaml("license: MIT") }
      assert_match "missing required attribute: name", ex.message

      ex = assert_raises(ParseError) { Spec.from_yaml("name: test") }
      assert_match "missing required attribute: version", ex.message
    end

    def test_fails_to_parse_dependencies
      str = <<-YAML
name: amethyst
version: 0.1.7
dependencies:
  github: spalger/crystal-mime
  branch: master
YAML
      ex = assert_raises(ParseError) { Spec.from_yaml(str) }
    end
  end
end
