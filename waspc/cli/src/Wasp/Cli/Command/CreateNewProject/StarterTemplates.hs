{-# LANGUAGE TupleSections #-}

module Wasp.Cli.Command.CreateNewProject.StarterTemplates
  ( getStarterTemplates,
    StarterTemplate (..),
    DirBasedTemplateMetadata (..),
    findTemplateByString,
    defaultStarterTemplate,
    readWaspProjectSkeletonFiles,
    getTemplateStartingInstructions,
  )
where

import Data.Foldable (find)
import Data.Text (Text)
import StrongPath (Dir', File', Path, Path', Rel, Rel', System, reldir, (</>))
import qualified System.FilePath as FP
import Wasp.Cli.Common (WaspProjectDir)
import qualified Wasp.Cli.GithubRepo as GhRepo
import qualified Wasp.Cli.Interactive as Interactive
import qualified Wasp.Data as Data
import Wasp.Util.IO (listDirectoryDeep, readFileStrict)
import qualified Wasp.Util.Terminal as Term

data StarterTemplate
  = -- | Template from a Github repo.
    GhRepoStarterTemplate !GhRepo.GithubRepoRef !DirBasedTemplateMetadata
  | -- | Template from a disk, that comes bundled with wasp CLI.
    LocalStarterTemplate !DirBasedTemplateMetadata
  | -- | Template that will be dynamically generated by Wasp AI based on user's input.
    AiGeneratedStarterTemplate

data DirBasedTemplateMetadata = DirBasedTemplateMetadata
  { _name :: !String,
    _path :: !(Path' Rel' Dir'), -- Path to a directory containing template files.
    _description :: !String,
    _buildStartingInstructions :: !StartingInstructionsBuilder
  }

instance Show StarterTemplate where
  show (GhRepoStarterTemplate _ metadata) = _name metadata
  show (LocalStarterTemplate metadata) = _name metadata
  show AiGeneratedStarterTemplate = "ai-generated"

instance Interactive.IsOption StarterTemplate where
  showOption = show

  showOptionDescription (GhRepoStarterTemplate _ metadata) = Just $ _description metadata
  showOptionDescription (LocalStarterTemplate metadata) = Just $ _description metadata
  showOptionDescription AiGeneratedStarterTemplate =
    Just "🤖 Describe an app in a couple of sentences and have Wasp AI generate initial code for you. (experimental)"

type StartingInstructionsBuilder = String -> String

{- HLINT ignore getTemplateStartingInstructions "Redundant $" -}

-- | Returns instructions for running the newly created (from the template) Wasp project.
-- Instructions assume that user is positioned right next to the just created project directory,
-- whose name is provided via projectDirName.
getTemplateStartingInstructions :: String -> StarterTemplate -> String
getTemplateStartingInstructions projectDirName = \case
  GhRepoStarterTemplate _ metadata -> _buildStartingInstructions metadata projectDirName
  LocalStarterTemplate metadata -> _buildStartingInstructions metadata projectDirName
  AiGeneratedStarterTemplate ->
    unlines
      [ styleText $ "To run your new app, do:",
        styleCode $ "    cd " <> projectDirName,
        styleCode $ "    wasp db migrate-dev",
        styleCode $ "    wasp start"
      ]

getStarterTemplates :: [StarterTemplate]
getStarterTemplates =
  [ defaultStarterTemplate,
    todoTsStarterTemplate,
    openSaasStarterTemplate,
    embeddingsStarterTemplate,
    AiGeneratedStarterTemplate
  ]

defaultStarterTemplate :: StarterTemplate
defaultStarterTemplate = basicStarterTemplate

{- HLINT ignore basicStarterTemplate "Redundant $" -}

basicStarterTemplate :: StarterTemplate
basicStarterTemplate =
  LocalStarterTemplate $
    DirBasedTemplateMetadata
      { _path = [reldir|basic|],
        _name = "basic",
        _description = "Simple starter template with a single page.",
        _buildStartingInstructions = \projectDirName ->
          unlines
            [ styleText $ "To run your new app, do:",
              styleCode $ "    cd " <> projectDirName,
              styleCode $ "    wasp db start"
            ]
      }

{- HLINT ignore openSaasStarterTemplate "Redundant $" -}

openSaasStarterTemplate :: StarterTemplate
openSaasStarterTemplate =
  simpleGhRepoTemplate
    ("open-saas", [reldir|.|])
    ( "saas",
      "Everything a SaaS needs! Comes with Auth, ChatGPT API, Tailwind, Stripe payments and more."
        <> " Check out https://opensaas.sh/ for more details."
    )
    ( \projectDirName ->
        unlines
          [ styleText $ "To run your new app, follow the instructions below:",
            styleText $ "",
            styleText $ "  1. Position into app's root directory:",
            styleCode $ "    cd " <> projectDirName FP.</> "app",
            styleText $ "",
            styleText $ "  2. Run the development database (and leave it running):",
            styleCode $ "    wasp db start",
            styleText $ "",
            styleText $ "  3. Open new terminal window (or tab) in that same dir and continue in it.",
            styleText $ "",
            styleText $ "  4. Apply initial database migrations:",
            styleCode $ "    wasp db migrate-dev",
            styleText $ "",
            styleText $ "  5. Create initial dot env file from the template:",
            styleCode $ "    cp .env.server.example .env.server",
            styleText $ "",
            styleText $ "  6. Last step: run the app!",
            styleCode $ "    wasp start",
            styleText $ "",
            styleText $ "Check the README for additional guidance and the link to docs!"
          ]
    )

{- HLINT ignore todoTsStarterTemplate "Redundant $" -}

todoTsStarterTemplate :: StarterTemplate
todoTsStarterTemplate =
  simpleGhRepoTemplate
    ("starters", [reldir|todo-ts|])
    ( "todo-ts",
      "Simple but well-rounded Wasp app implemented with Typescript & full-stack type safety."
    )
    ( \projectDirName ->
        unlines
          [ styleText $ "To run your new app, do:",
            styleCode $ "    cd " ++ projectDirName,
            styleCode $ "    wasp db migrate-dev",
            styleCode $ "    wasp start",
            styleText $ "",
            styleText $ "Check the README for additional guidance!"
          ]
    )

{- Functions for styling instructions. Their names are on purpose of same length, for nicer code formatting. -}

styleCode :: String -> String
styleCode = Term.applyStyles [Term.Bold]

styleText :: String -> String
styleText = id

{- -}

{- HLINT ignore embeddingsStarterTemplate "Redundant $" -}

embeddingsStarterTemplate :: StarterTemplate
embeddingsStarterTemplate =
  simpleGhRepoTemplate
    ("starters", [reldir|embeddings|])
    ( "embeddings",
      "Comes with code for generating vector embeddings and performing vector similarity search."
    )
    ( \projectDirName ->
        unlines
          [ styleText $ "To run your new app, follow the instructions below:",
            styleText $ "",
            styleText $ "  1. Position into app's root directory:",
            styleCode $ "    cd " <> projectDirName,
            styleText $ "",
            styleText $ "  2. Create initial dot env file from the template and fill in your API keys:",
            styleCode $ "    cp .env.server.example .env.server",
            styleText $ "    Fill in your API keys!",
            styleText $ "",
            styleText $ "  3. Run the development database (and leave it running):",
            styleCode $ "    wasp db start",
            styleText $ "",
            styleText $ "  4. Open new terminal window (or tab) in that same dir and continue in it.",
            styleText $ "",
            styleText $ "  5. Apply initial database migrations:",
            styleCode $ "    wasp db migrate-dev",
            styleText $ "",
            styleText $ "  6. Run wasp seed script that will generate embeddings from the text files in src/shared/docs:",
            styleCode $ "    wasp db seed",
            styleText $ "",
            styleText $ "  7. Last step: run the app!",
            styleCode $ "    wasp start",
            styleText $ "",
            styleText $ "Check the README for more detailed instructions and additional guidance!"
          ]
    )

simpleGhRepoTemplate :: (String, Path' Rel' Dir') -> (String, String) -> StartingInstructionsBuilder -> StarterTemplate
simpleGhRepoTemplate (repoName, tmplPathInRepo) (tmplDisplayName, tmplDescription) buildStartingInstructions =
  GhRepoStarterTemplate
    ( GhRepo.GithubRepoRef
        { GhRepo._repoOwner = waspGhOrgName,
          GhRepo._repoName = repoName,
          GhRepo._repoReferenceName = waspVersionTemplateGitTag
        }
    )
    ( DirBasedTemplateMetadata
        { _name = tmplDisplayName,
          _description = tmplDescription,
          _path = tmplPathInRepo,
          _buildStartingInstructions = buildStartingInstructions
        }
    )

waspGhOrgName :: String
waspGhOrgName = "wasp-lang"

-- NOTE: As version of Wasp CLI changes, so we should update this tag name here,
--   and also create it on gh repos of templates.
--   By tagging templates for each version of Wasp CLI, we ensure that each release of
--   Wasp CLI uses correct version of templates, that work with it.
waspVersionTemplateGitTag :: String
waspVersionTemplateGitTag = "wasp-v0.12-template"

findTemplateByString :: [StarterTemplate] -> String -> Maybe StarterTemplate
findTemplateByString templates query = find ((== query) . show) templates

readWaspProjectSkeletonFiles :: IO [(Path System (Rel WaspProjectDir) File', Text)]
readWaspProjectSkeletonFiles = do
  skeletonFilesDir <- (</> [reldir|Cli/templates/skeleton|]) <$> Data.getAbsDataDirPath
  skeletonFilePaths <- listDirectoryDeep skeletonFilesDir
  mapM (\path -> (path,) <$> readFileStrict (skeletonFilesDir </> path)) skeletonFilePaths
