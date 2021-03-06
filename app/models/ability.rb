class Ability
  include Hydra::Ability
  self.ability_logic += [:role_permissions]
  self.ability_logic += [:review_permissions]
  self.ability_logic += [:ingest_permissions]
  self.ability_logic += [:template_permissions]
  self.ability_logic += [:download_permissions]

  def role_permissions
    if current_user.admin?
      can [:create, :show, :edit, :destroy, :add_user, :remove_user, :index, :add_ip_range, :remove_ip_range], Role
    end
  end

  def review_permissions
    can [:review], GenericAsset if current_user.admin? || current_user.archivist?
  end

  def download_permissions
    can [:download], Document
    can [:download], Audio
  end

  def ingest_permissions
    # Forcibly deny create and update permissions to override built-in Hydra rules
    cannot [:create, :update, :destroy], GenericAsset

    if current_user.submitter? || current_user.archivist? || current_user.admin?
      can [:create], GenericAsset
    end

    if current_user.archivist? || current_user.admin?
      can [:update, :destroy], GenericAsset
    end
  end

  def template_permissions
    # Forcibly deny permissions to override built-in Hydra rules
    cannot [:manage], Template

    if current_user.archivist? || current_user.admin?
      can [:manage], Template
    end
  end
end
