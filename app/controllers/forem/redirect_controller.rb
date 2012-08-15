class Forem::RedirectController < ApplicationController
    def forum
        return redirect_to forum_path(params[:forum_id])
    end

    def topic
        return redirect_to topic_path(params[:topic_id])
    end
end
