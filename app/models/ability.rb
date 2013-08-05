class Ability
  include CanCan::Ability

  def initialize(user)
    can [:index, :show], Radical
    can [:index, :show], Character
    
    can :new, Visitor
    
    if user.present? 
      case user.class.name 
 
      when "Admin"
        can :manage, Radical
        can :manage, Character
        can :new, Visitor
      end
            
    # else
    #   can [:new, :create], User
    end
  end
end
