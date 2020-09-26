package com.netease.audioroom.demo.adapter;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.netease.audioroom.demo.R;
import com.netease.audioroom.demo.base.adapter.BaseAdapter;
import com.netease.yunxin.nertc.nertcvoiceroom.model.VoiceRoomMessage;

import java.util.ArrayList;

public class MessageListAdapter extends BaseAdapter<VoiceRoomMessage> {


    public MessageListAdapter(ArrayList<VoiceRoomMessage> dataList, Context context) {
        super(dataList, context);
    }

    @Override
    protected RecyclerView.ViewHolder onCreateBaseViewHolder(ViewGroup parent, int viewType) {
        return new MsgHolder(layoutInflater.inflate(R.layout.item_msg_list, parent, false));
    }

    @Override
    protected void onBindBaseViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        MsgHolder msgHolder = (MsgHolder) holder;

        VoiceRoomMessage message = getItem(position);
        if (message == null) {
            return;
        }
        if (message.type == VoiceRoomMessage.Type.TEXT) {
            msgHolder.tvNick.setText(message.nick + "：");
            msgHolder.tvContent.setText(message.content);
        } else if (message.type == VoiceRoomMessage.Type.EVENT) {
            msgHolder.tvNick.setText(message.content);
            msgHolder.tvContent.setText(null);
        }

    }


    private static class MsgHolder extends RecyclerView.ViewHolder {
        TextView tvNick;
        TextView tvContent;

        public MsgHolder(View itemView) {
            super(itemView);
            tvNick = itemView.findViewById(R.id.tv_nick);
            tvContent = itemView.findViewById(R.id.tv_content);
        }
    }
}
